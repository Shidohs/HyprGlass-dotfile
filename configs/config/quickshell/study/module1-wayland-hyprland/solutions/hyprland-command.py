#!/usr/bin/env python3
"""
Ejercicio 1.5 - Solucion: Enviar comandos a Hyprland via socket

Este script envia comandos a Hyprland directamente via su socket UNIX,
sin usar hyprctl.

Uso:
    python3 hyprland-command.py "dispatch exec kitty"
    python3 hyprland-command.py "keyword layerrule blur,quickshell"
"""

import socket
import os
import sys

def get_hyprland_command_socket():
    """Obtiene la ruta del socket de comandos de Hyprland."""
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        print("ERROR: HYPRLAND_INSTANCE_SIGNATURE no esta definido.")
        sys.exit(1)
    
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    return f"{runtime_dir}/hypr/{signature}/.socket.sock"

def send_command(command):
    """Envia un comando al socket de Hyprland y devuelve la respuesta."""
    socket_path = get_hyprland_command_socket()
    
    if not os.path.exists(socket_path):
        print(f"ERROR: Socket no encontrado en {socket_path}")
        sys.exit(1)
    
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(socket_path)
        sock.sendall(command.encode("utf-8"))
        
        response = b""
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                break
            response += chunk
        
        return response.decode("utf-8").strip()

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 hyprland-command.py <comando>")
        print("Ejemplos:")
        print('  python3 hyprland-command.py "dispatch exec kitty"')
        print('  python3 hyprland-command.py "keyword layerrule blur,quickshell"')
        sys.exit(1)
    
    command = " ".join(sys.argv[1:])
    print(f"Enviando comando: {command}")
    
    response = send_command(command)
    print(f"Respuesta: {response}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrumpido por el usuario.")
    except Exception as e:
        print(f"ERROR: {e}")
