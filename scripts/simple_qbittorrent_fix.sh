#!/bin/bash
# Script simple para configurar qBittorrent

CONFIG_FILE="/home/gato99/Documentos/proyectos/otros/jellyfin/config/qbittorrent/qBittorrent/qBittorrent.conf"

echo "=== Configurando qBittorrent ==="

# Hacer copia de seguridad
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

# Lista de trackers
TRACKERS="udp://tracker.opentrackr.org:1337/announce
udp://tracker.openbittorrent.com:6969/announce
udp://open.demonii.com:1337/announce
udp://tracker.coppersurfer.tk:6969/announce
udp://tracker.leechers-paradise.org:6969/announce
udp://exodus.desync.com:6969/announce
udp://tracker.pomf.se:80/announce
udp://tracker.internetwarriors.net:1337/announce
udp://9.rarbg.to:2710/announce
udp://9.rarbg.me:2710/announce
udp://open.stealth.si:80/announce"

# Crear archivo temporal con las modificaciones
cat > /tmp/qbittorrent_fixed.conf << EOF
[Application]
FileLogger\Age=1
FileLogger\AgeType=1
FileLogger\Backup=true
FileLogger\DeleteOld=true
FileLogger\Enabled=true
FileLogger\MaxSizeBytes=66560
FileLogger\Path=/config/qBittorrent/logs

[AutoRun]
enabled=false
program=

[BitTorrent]
Session\DefaultSavePath=/media/torrents/
Session\DHTEnabled=true
Session\ExcludedFileNames=
Session\IgnoreLimitsOnLAN=true
Session\LSDEnabled=true
Session\MaxActiveDownloads=5
Session\MaxUploadsPerTorrent=10
Session\PeXEnabled=true
Session\Port=6881
Session\QueueingSystemEnabled=true
Session\SSL\Port=44107
Session\TempPath=/media/torrents/incomplete/
Session\uTPRateLimited=false

[Core]
AutoDeleteAddedTorrentFile=Never

[LegalNotice]
Accepted=true

[Meta]
MigrationVersion=8

[Network]
Cookies=@Invalid()
PortForwardingEnabled=false
Proxy\HostnameLookupEnabled=false
Proxy\Profiles\BitTorrent=true
Proxy\Profiles\Misc=true
Proxy\Profiles\RSS=true

[Preferences]
Connection\PortRangeMin=6881
Connection\UPnP=false
Downloads\SavePath=/media/torrents/
Downloads\TempPath=/media/torrents/incomplete/
General\Locale=es
MailNotification\req_auth=true
WebUI\Address=*
WebUI\AuthSubnetWhitelist=@Invalid()
WebUI\Password_PBKDF2="@ByteArray(bvrh08CEs1nJBn9aIEmipg==:bob9U5HZ7YA/B1OuzkrPB4ll33LFtY1aHHHm900iA7UQTfANnaRqxKkV7TBJOH2sMcyh8mtIGoNbN0XcHrWYbw==)"
WebUI\ServerDomains=*

[RSS]
AutoDownloader\DownloadRepacks=true
AutoDownloader\SmartEpisodeFilter=s(\\d+)e(\\d+), (\\d+)x(\\d+), "(\\d{4}[.\\-]\\d{1,2}[.\\-]\\d{1,2})", "(\\d{1,2}[.\\-]\\d{1,2}[.\\-]\\d{4})"

[AddTrackers]
Trackers=$TRACKERS
EOF

# Copiar archivo modificado
cp /tmp/qbittorrent_fixed.conf "$CONFIG_FILE"

echo "✅ Configuración aplicada:"
echo "   - DHT habilitado"
echo "   - PeX habilitado"
echo "   - LSD habilitado"
echo "   - MaxActiveDownloads aumentado a 5"
echo "   - Trackers automáticos añadidos"

echo ""
echo "🔄 Reiniciando qBittorrent..."
docker compose --profile media restart qbittorrent

echo ""
echo "⏳ Esperando 10 segundos..."
sleep 10

echo ""
echo "🎯 Instrucciones:"
echo "1. Accede a http://127.0.0.1:8080/"
echo "2. Para torrents existentes, añade trackers manualmente:"
echo "   - Selecciona torrents lentos"
echo "   - Botón derecho > 'Trackers' > 'Agregar nuevo tracker'"
echo "   - Copia y pega esta lista:"
echo ""
echo "$TRACKERS"
echo ""
echo "3. Verifica en 'Opciones' → 'BitTorrent' que:"
echo "   - DHT esté activado"
echo "   - PeX esté activado"
echo "   - LSD esté activado"
echo ""
echo "🔄 Para revertir:"
echo "   cp '${CONFIG_FILE}.backup' '$CONFIG_FILE'"
echo "   docker compose --profile media restart qbittorrent"