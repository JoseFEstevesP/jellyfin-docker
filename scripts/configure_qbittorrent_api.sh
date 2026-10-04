#!/bin/bash
# Script para configurar qBittorrent usando API REST

echo "=== Configurando qBittorrent vía API REST ==="
echo "Este método es más confiable porque configura directamente el cliente en ejecución"

echo ""
echo "📋 Lista de trackers para añadir manualmente:"

cat << 'TRACKERS'
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
TRACKERS

echo ""
echo "🎯 Pasos para configurar manualmente (más efectivo):"
echo ""
echo "1. Accede a http://127.0.0.1:8080/"
echo "   Usuario: admin"
echo "   Contraseña: adminadmin (o la que hayas configurado)"
echo ""
echo "2. Activa DHT, PeX y LSD:"
echo "   - Ve a 'Opciones' (engranaje arriba a la derecha)"
echo "   - Sección 'BitTorrent'"
echo "   - Marca todas estas casillas:"
echo "     • Habilitar DHT (red distribuida)"
echo "     • Habilitar intercambio de pares (PeX)"
echo "     • Habilitar descubrimiento local de pares (LSD)"
echo "   - Haz clic en 'Aplicar'"
echo ""
echo "3. Añade trackers a torrents existentes:"
echo "   - Selecciona los torrents lentos (Ctrl+clic para múltiples)"
echo "   - Botón derecho > 'Trackers' > 'Agregar nuevos trackers'"
echo "   - Copia y pega la lista de arriba"
echo "   - Haz clic en 'Aceptar'"
echo ""
echo "4. Configuración adicional recomendada:"
echo "   - En 'Opciones' → 'Velocidad':"
echo "     • Verifica que no haya límites de descarga/subida"
echo "   - En 'Opciones' → 'Conectividad':"
echo "     • Puerto de escucha: 6881 (verifica que esté abierto en router)"
echo "     • Marca 'Usar UPnP / NAT-PMP' si tu router lo soporta"
echo ""
echo "5. Para nuevos torrents, qBittorrent usará automáticamente:"
echo "   - Los trackers del archivo .torrent"
echo "   - Los trackers de la lista global (si los añadiste)"
echo "   - DHT/PeX/LSD para encontrar más peers"
echo ""
echo "💡 Consejos para mejor velocidad:"
echo "   - Descarga torrents populares con muchas semillas (seeders)"
echo "   - Verifica tu conexión a Internet"
echo "   - Si estás detrás de un router NAT:"
echo "     • Configura port forwarding para el puerto 6881"
echo "     • O activa UPnP en qBittorrent y router"
echo "   - Evita límites de ISP para tráfico P2P"
echo ""
echo "🔧 Si necesitas ayuda con port forwarding:"
echo "   1. Accede a tu router (normalmente 192.168.1.1 o 192.168.0.1)"
echo "   2. Busca 'Port Forwarding' o 'Aplicaciones y juegos'"
echo "   3. Añade una regla: Puerto 6881 TCP/UDP → IP de tu servidor"
echo ""
echo "El stack Jellyfin está optimizado para qBittorrent específicamente"
echo "porque Sonarr/Radarr se integran directamente con él."