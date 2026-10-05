#!/bin/bash
# Script para configurar trackers adicionales en qBittorrent

set -e

echo "Configurando trackers adicionales en qBittorrent..."

# Crear una lista actualizada de trackers públicos
cat > /tmp/trackers.txt << 'EOF'
udp://tracker.opentrackr.org:1337/announce
udp://tracker.openbittorrent.com:6969/announce
udp://open.demonii.com:1337/announce
udp://tracker.coppersurfer.tk:6969/announce
udp://tracker.leechers-paradise.org:6969/announce
udp://exodus.desync.com:6969/announce
udp://tracker.pomf.se:80/announce
udp://tracker.internetwarriors.net:1337/announce
udp://9.rarbg.to:2710/announce
udp://9.rarbg.me:2710/announce
udp://open.stealth.si:80/announce
udp://tracker.cyberia.is:6969/announce
udp://tracker.torrent.eu.org:451/announce
udp://tracker.moeking.me:6969/announce
udp://tracker.dler.org:6969/announce
udp://ipv4.tracker.harry.lu:80/announce
udp://tracker.tiny-vps.com:6969/announce
udp://tracker.opentrackr.org:1337/announce
http://tracker.opentrackr.org:1337/announce
wss://tracker.openwebtorrent.com:443/announce
wss://tracker.btorrent.xyz:443/announce
https://tracker.nanoha.org:443/announce
udp://opentracker.i2p.rocks:6969/announce
http://opentracker.i2p.rocks:6969/announce
udp://open.nyap2p.com:6969/announce
http://open.nyap2p.com:8080/announce
udp://tracker.0x.tf:6969/announce
http://tracker.0x.tf:6969/announce
udp://tracker.bittor.pw:1337/announce
EOF

echo "Trackers creados en /tmp/trackers.txt"
echo "Total de trackers: $(wc -l < /tmp/trackers.txt)"

echo ""
echo "Para aplicar estos trackers en qBittorrent:"
echo ""
echo "1. Accede a http://127.0.0.1:8080/"
echo "2. Inicia sesión con tus credenciales"
echo "3. Ve a 'Opciones' (icono de engranaje)"
echo "4. Ve a la sección 'BitTorrent'"
echo "5. En 'Trackers automáticos', haz clic en 'Actualizar trackers automáticos'"
echo "6. O para añadirlos manualmente a torrents existentes:"
echo "   - Selecciona los torrents lentos"
echo "   - Botón derecho > 'Trackers' > 'Agregar nuevo tracker'"
echo "   - Copia y pega los trackers de arriba"
echo ""
echo "También recomiendo activar:"
echo "- DHT (Red distribuida de hash)"
echo "- PeX (Intercambio de pares)"
echo "- LSD (Descubrimiento local de pares)"
echo ""
echo "Estas opciones están en 'Opciones' → 'BitTorrent'"
echo ""
echo "Para verificar la configuración actual de DHT/PeX/LSD:"
echo "docker compose --profile media exec qbittorrent cat /config/qBittorrent/qBittorrent.conf | grep -E '(DHT|PeX|LSD)'"