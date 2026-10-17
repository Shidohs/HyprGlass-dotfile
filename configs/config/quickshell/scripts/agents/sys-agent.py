#!/usr/bin/env python3
import glob
import json
import os
import shutil
import subprocess
import time

BASE_SAMPLE_SECONDS = 2
GPU_SAMPLE_MULTIPLIER = 2
_CPU_TEMP_SENSORS = None
_AMD_GPU_BUSY_PATHS = None
_NET_RX_FILES = None
_NET_TX_FILES = None


def discover_cpu_temp_sensors():
    sensors = []
    for temp_path in glob.glob("/sys/class/thermal/thermal_zone*/temp"):
        type_path = temp_path.replace("temp", "type")
        try:
            with open(type_path, "r") as handle:
                tz_type = handle.read().strip()
            if tz_type == "x86_pkg_temp" or "k10temp" in tz_type:
                sensors.append(temp_path)
        except OSError:
            continue
    return sensors


def discover_amd_gpu_busy_paths():
    return glob.glob("/sys/class/drm/card*/device/gpu_busy_percent")


def discover_net_stat_files(direction):
    files = []
    pattern = f"/sys/class/net/*/statistics/{direction}_bytes"
    for path in glob.glob(pattern):
        if "lo/statistics" not in path:
            files.append(path)
    return files


def get_cpu_temp():
    global _CPU_TEMP_SENSORS
    if _CPU_TEMP_SENSORS is None:
        _CPU_TEMP_SENSORS = discover_cpu_temp_sensors()

    max_temp = 0
    for temp_path in _CPU_TEMP_SENSORS:
        try:
            with open(temp_path, "r") as handle:
                temp_value = int(handle.read().strip())
            if temp_value > max_temp:
                max_temp = temp_value
        except OSError:
            continue
    return int(max_temp / 1000) if max_temp > 0 else 0


def has_nvidia_smi():
    return shutil.which("nvidia-smi") is not None


def get_gpu_info(nvidia_available=None):
    global _AMD_GPU_BUSY_PATHS
    usage, temp = 0, 0
    try:
        # Check NVIDIA
        if nvidia_available is None:
            nvidia_available = has_nvidia_smi()
        if nvidia_available:
            out = subprocess.check_output(
                [
                    "nvidia-smi",
                    "--query-gpu=utilization.gpu,temperature.gpu",
                    "--format=csv,noheader,nounits",
                ],
                universal_newlines=True,
            )
            parts = [p.strip() for p in out.split(",")]
            if len(parts) >= 2:
                usage = int(parts[0])
                temp = int(parts[1])
            return "nvidia", usage, temp

        # Check AMD
        if _AMD_GPU_BUSY_PATHS is None:
            _AMD_GPU_BUSY_PATHS = discover_amd_gpu_busy_paths()
        if _AMD_GPU_BUSY_PATHS:
            for path in _AMD_GPU_BUSY_PATHS:
                try:
                    with open(path, "r") as handle:
                        usage = int(handle.read().strip())
                    hwmon_dir = os.path.dirname(os.path.dirname(path)) + "/hwmon/hwmon*"
                    temp_paths = glob.glob(hwmon_dir + "/temp1_input")
                    if temp_paths:
                        with open(temp_paths[0], "r") as handle:
                            temp = int(int(handle.read().strip()) / 1000)
                    return "amd", usage, temp
                except OSError:
                    continue
    except Exception:
        pass
    return "unknown", 0, 0


def read_cpu_stat():
    try:
        with open("/proc/stat", "r") as handle:
            line = handle.readline()
        if line.startswith("cpu "):
            parts = line.split()
            user, nice, system, idle, iowait, irq, softirq, steal = map(
                int, parts[1:9]
            )
            total = user + nice + system + idle + iowait + irq + softirq + steal
            idle_total = idle + iowait
            return total, idle_total
    except OSError:
        pass
    return 0, 0


def get_ram_info():
    try:
        with open("/proc/meminfo", "r") as handle:
            mem_total = 0
            mem_avail = 0
            for line in handle:
                parts = line.split()
                if line.startswith("MemTotal:"):
                    mem_total = int(parts[1]) * 1024
                elif line.startswith("MemAvailable:"):
                    mem_avail = int(parts[1]) * 1024
                if mem_total and mem_avail:
                    break
            if mem_total > 0:
                used = mem_total - mem_avail
                percent = int((used / mem_total) * 100)
                return percent, used, mem_total
    except OSError:
        pass
    return 0, 0, 0


def get_disk_info():
    try:
        st = os.statvfs("/")
        total = st.f_blocks * st.f_frsize
        free = st.f_bavail * st.f_frsize
        used = total - free
        percent = int((used / total) * 100) if total > 0 else 0
        return percent, used, total
    except:
        pass
    return 0, 0, 0


def get_net_bytes():
    global _NET_RX_FILES, _NET_TX_FILES
    if _NET_RX_FILES is None:
        _NET_RX_FILES = discover_net_stat_files("rx")
    if _NET_TX_FILES is None:
        _NET_TX_FILES = discover_net_stat_files("tx")

    rx = 0
    tx = 0
    try:
        for path in _NET_RX_FILES:
            with open(path, "r") as handle:
                rx += int(handle.read().strip())
        for path in _NET_TX_FILES:
            with open(path, "r") as handle:
                tx += int(handle.read().strip())
    except OSError:
        pass
    return rx, tx


def get_uptime():
    try:
        with open("/proc/uptime", "r") as handle:
            uptime = float(handle.read().split()[0])
            hours = int(uptime // 3600)
            minutes = int((uptime % 3600) // 60)
            if hours > 0:
                return f"{hours}h {minutes}m"
            else:
                return f"{minutes}m"
    except OSError:
        pass
    return "0m"


def compute_cpu_usage(prev_total, prev_idle, total_cpu, idle_cpu):
    diff_total = total_cpu - prev_total
    diff_idle = idle_cpu - prev_idle
    cpu_usage = 0
    if diff_total > 0:
        cpu_usage = int(100 * (diff_total - diff_idle) / diff_total)
    return cpu_usage


def compute_net_rates(prev_rx, prev_tx, rx, tx, elapsed):
    rx_rate = int((rx - prev_rx) / elapsed) if elapsed > 0 else 0
    tx_rate = int((tx - prev_tx) / elapsed) if elapsed > 0 else 0
    return rx_rate, tx_rate


def main():
    prev_total_cpu, prev_idle_cpu = read_cpu_stat()
    prev_rx, prev_tx = get_net_bytes()
    last_net_time = time.monotonic()

    nvidia_available = has_nvidia_smi()
    gpu_state = get_gpu_info(nvidia_available=nvidia_available)

    disk_state = get_disk_info()
    uptime_state = get_uptime()
    net_rates = (0, 0)

    tick = 0
    first_run = True

    while True:
        if first_run:
            time.sleep(0.5)
            first_run = False
        else:
            time.sleep(BASE_SAMPLE_SECONDS)
        tick += 1

        total_cpu, idle_cpu = read_cpu_stat()
        cpu_usage = compute_cpu_usage(prev_total_cpu, prev_idle_cpu, total_cpu, idle_cpu)
        cpu_temp = get_cpu_temp()
        prev_total_cpu = total_cpu
        prev_idle_cpu = idle_cpu

        ram_percent, ram_used, ram_total = get_ram_info()

        if tick == 1 or tick % 2 == 0:
            current_time = time.monotonic()
            rx, tx = get_net_bytes()
            elapsed = current_time - last_net_time
            if elapsed <= 0:
                elapsed = 1
            net_rates = compute_net_rates(prev_rx, prev_tx, rx, tx, elapsed)
            prev_rx = rx
            prev_tx = tx
            last_net_time = current_time

            disk_state = get_disk_info()
            uptime_state = get_uptime()

        if tick == 1 or tick % 4 == 0:
            gpu_state = get_gpu_info(nvidia_available=nvidia_available)

        data = {
            "cpu": {"usage": cpu_usage, "temp": cpu_temp},
            "gpu": {"type": gpu_state[0], "usage": gpu_state[1], "temp": gpu_state[2]},
            "ram": {"usage": ram_percent, "used": ram_used, "total": ram_total},
            "disk": {"usage": disk_state[0], "used": disk_state[1], "total": disk_state[2]},
            "network": {"rx": net_rates[0], "tx": net_rates[1]},
            "uptime": uptime_state,
        }

        print(json.dumps(data, separators=(",", ":")), flush=True)

if __name__ == "__main__":
    main()
