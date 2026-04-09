import socket
import requests
import sys

# Configuración
UDP_IP = "0.0.0.0" 
UDP_PORT = 514
# Asegúrate de usar la URL de n8n que tengas activa (Test o Production)
WEBHOOK_URL = "http://localhost:5678/webhook-test/pfsense-logs"
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))
sock.settimeout(1.0)

print(f"--- PUENTE ACTIVO --- Escuchando puerto {UDP_PORT}...")
print("Presiona Ctrl+C para detener.")

try:
    while True:
        try:
            data, addr = sock.recvfrom(2048)
            log_line = data.decode('utf-8', errors='ignore')
            
            # Envío a n8n
            try:
                requests.post(WEBHOOK_URL, json={"mensaje": log_line}, timeout=2)
                print(f"OK: Log enviado desde {addr[0]}")
            except:
                print("Error: No se pudo contactar con n8n")
                
        except socket.timeout:
            continue
except KeyboardInterrupt:
    print("\nDeteniendo el sistema...")
    sock.close()
    sys.exit(0)