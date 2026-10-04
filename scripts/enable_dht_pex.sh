#!/bin/bash
# Script para habilitar DHT, PeX y LSD en qBittorrent

set -e

CONFIG_FILE="/home/gato99/Documentos/proyectos/otros/jellyfin/config/qbittorrent/qBittorrent/qBittorrent.conf"

echo "Habilitando DHT, PeX y LSD en qBittorrent..."
echo "Archivo de configuración: $CONFIG_FILE"

# Hacer una copia de seguridad
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# Verificar si ya existen las configuraciones
if grep -q "Session\AddTrackers" "$CONFIG_FILE"; then
    echo "La configuración AddTrackers ya existe, actualizando..."
else
    echo "Añadiendo configuración AddTrackers..."
    echo "" >> "$CONFIG_FILE"
    echo "[AddTrackers]" >> "$CONFIG_FILE"
fi

# Actualizar/agregar configuraciones
python3 << 'EOF'
import configparser
import os

config_file = "/home/gato99/Documentos/proyectos/otros/jellyfin/config/qbittorrent/qBittorrent/qBittorrent.conf"

# Leer archivo de configuración
config = configparser.ConfigParser()
config.read(config_file)

# Asegurar que la sección [BitTorrent] existe
if 'BitTorrent' not in config:
    config['BitTorrent'] = {}

# Habilitar DHT, PeX y LSD
config['BitTorrent']['Session\DHTEnabled'] = 'true'
config['BitTorrent']['Session\PeXEnabled'] = 'true'
config['BitTorrent']['Session\LSDEnabled'] = 'true'

# Añadir lista de trackers automáticos
if 'AddTrackers' not in config:
    config['AddTrackers'] = {}

trackers_list = """udp://tracker.opentrackr.org:1337/announce
udp://tracker.openbittorrent.com:6969/announce
udp://open.demonii.com:1337/announce
udp://tracker.coppersurfer.tk:6969/announce
udp://tracker.leechers-paradise.org:6969/announce
udp://exodus.desync.com:6969/announce
udp://tracker.pomf.se:80/announce"""

config['AddTrackers']['Trackers'] = trackers_list

# Escribir configuración actualizada
with open(config_file, 'w') as f:
    config.write(f, space_around_delimiters=False)

print("Configuración actualizada exitosamente")
EOF

echo ""
echo "Reiniciando qBittorrent para aplicar los cambios..."
docker compose --profile media restart qbittorrent

echo ""
echo "Esperando a que qBittorrent se reinicie..."
sleep 10

echo ""
echo "Configuración aplicada:"
echo "- DHT habilitado"
echo "- PeX habilitado"
echo "- LSD habilitado"
echo "- Trackers automáticos añadidos"
echo ""
echo "Copia de seguridad creada: ${CONFIG_FILE}.backup-*"
echo ""
echo "Para verificar los cambios, accede a:"
echo "http://127.0.0.1:8080/ → Opciones → BitTorrent"
echo ""
echo "También puedes verificar con:"
echo "docker compose --profile media exec qbittorrent cat /config/qBittorrent/qBittorrent.conf | grep -E '(DHT|PeX|LSD|Trackers)'"