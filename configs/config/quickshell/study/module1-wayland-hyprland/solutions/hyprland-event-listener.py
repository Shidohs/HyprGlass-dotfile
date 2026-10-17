#!/usr/bin/env python3
"""
Ejercicio 1.4 - Solucion: Escuchar eventos de Hyprland via socket2

Este script se conecta al socket de eventos de Hyprland y muestra
cada evento con un timestamp legible.

Uso:
    python3 hyprland-event-listener.py
"""

import socket
import os
import sys
from datetime import datetime

def get_hyprland_socket():
    """Obtiene la ruta del socket2 de Hyprland."""
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        print("ERROR: HYPRLAND_INSTANCE_SIGNATURE no esta definido.")
        print("Asegurate de estar ejecutando dentro de una sesion Hyprland.")
        sys.exit(1)
    
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    return f"{runtime_dir}/hypr/{signature}/.socket2.sock"

def parse_event(raw_event):
    """Parsea un evento de Hyprland y devuelve una estructura legible."""
    raw = raw_event.strip()
    if not raw:
        return None
    
    if ">>" in raw:
        event_type, data = raw.split(">>", 1)
    else:
        event_type = raw
        data = ""
    
    return {
        "type": event_type,
        "data": data,
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
    }

def main():
    socket_path = get_hyprland_socket()
    
    if not os.path.exists(socket_path):
        print(f"ERROR: Socket no encontrado en {socket_path}")
        sys.exit(1)
    
    print(f"Conectando a: {socket_path}")
    print("Escuchando eventos de Hyprland (Ctrl+C para salir)...\n")
    
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(socket_path)
        
        buffer = ""
        while True:
            data = sock.recv(4096).decode("utf-8")
            if not data:
                print("Conexion cerrada por el servidor.")
                break
            
            buffer += data
            
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                event = parse_event(line)
                
                if event:
                    print(f"[{event['timestamp']}] {event['type']}")
                    if event['data']:
                        print(f"  Datos: {event['data']}")
                    print()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrumpido por el usuario.")
    except ConnectionRefusedError:
        print("ERROR: No se pudo conectar al socket. Hyprland esta corriendo?")
    except Exception as e:
        print(f"ERROR: {e}")
