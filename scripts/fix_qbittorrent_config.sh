#!/bin/bash
# Script para configurar qBittorrent con trackers adicionales y optimizaciones

set -e

CONFIG_FILE="/home/gato99/Documentos/proyectos/otros/jellyfin/config/qbittorrent/qBittorrent/qBittorrent.conf"

echo "=== Configurando qBittorrent para mejor velocidad ==="

# Hacer copia de seguridad
BACKUP_FILE="${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "Copia de seguridad creada: $BACKUP_FILE"

# Lista de trackers populares
TRACKERS_LIST="udp://tracker.opentrackr.org:1337/announce
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

# Leer el archivo existente
CONTENT=$(cat "$CONFIG_FILE")

# Buscar la sección [BitTorrent]
if echo "$CONTENT" | grep -q "\[BitTorrent\]"; then
    # Ya existe la sección, vamos a modificar las líneas después de ella
    echo "Sección [BitTorrent] encontrada, actualizando configuración..."
    
    # Crear nuevo contenido
    NEW_CONTENT=""
    IFS=$'\n'
    in_bt_section=false
    bt_updated=false
    
    for line in $CONTENT; do
        if [[ "$line" == "[BitTorrent]" ]]; then
            in_bt_section=true
            NEW_CONTENT+="$line"$'\n'
        elif [[ "$line" == "["* && $in_bt_section == true ]]; then
            # Salimos de la sección BitTorrent, agregamos las configuraciones antes de salir
            if [[ $bt_updated == false ]]; then
                NEW_CONTENT+="Session\\DHTEnabled=true"$'\n'
                NEW_CONTENT+="Session\\PeXEnabled=true"$'\n'
                NEW_CONTENT+="Session\\LSDEnabled=true"$'\n'
                bt_updated=true
            fi
            in_bt_section=false
            NEW_CONTENT+="$line"$'\n'
        elif [[ $in_bt_section == true ]]; then
            # Estamos en la sección BitTorrent
            if [[ "$line" == Session\\DHTEnabled* ]]; then
                NEW_CONTENT+="Session\\DHTEnabled=true"$'\n'
                bt_updated=true
            elif [[ "$line" == Session\\PeXEnabled* ]]; then
                NEW_CONTENT+="Session\\PeXEnabled=true"$'\n'
                bt_updated=true
            elif [[ "$line" == Session\\LSDEnabled* ]]; then
                NEW_CONTENT+="Session\\LSDEnabled=true"$'\n'
                bt_updated=true
            else
                NEW_CONTENT+="$line"$'\n'
            fi
        else
            NEW_CONTENT+="$line"$'\n'
        fi
    done
    
    # Si todavía no agregamos las configuraciones, agregarlas al final del archivo
    if [[ $bt_updated == false ]]; then
        # Buscar el final de la sección BitTorrent
        if echo "$NEW_CONTENT" | grep -q "\[BitTorrent\]"; then
            # Agregar después de la última línea de BitTorrent antes de la siguiente sección
            TEMP_FILE=$(mktemp)
            echo "$NEW_CONTENT" > "$TEMP_FILE"
            
            # Insertar las líneas después de la última línea de BitTorrent
            awk '/\[BitTorrent\]/ {print; in_bt=1; next} 
                 in_bt && /^\[/ {print "Session\\DHTEnabled=true"; print "Session\\PeXEnabled=true"; print "Session\\LSDEnabled=true"; in_bt=0; print; next}
                 {print}' "$TEMP_FILE" > "$CONFIG_FILE"
            rm "$TEMP_FILE"
        else
            echo "$NEW_CONTENT" > "$CONFIG_FILE"
        fi
    else
        echo "$NEW_CONTENT" > "$CONFIG_FILE"
    fi
else
    # No existe la sección, agregarla
    echo "Agregando sección [BitTorrent] con configuraciones..."
    echo "" >> "$CONFIG_FILE"
    echo "[BitTorrent]" >> "$CONFIG_FILE"
    echo "Session\DHTEnabled=true" >> "$CONFIG_FILE"
    echo "Session\PeXEnabled=true" >> "$CONFIG_FILE"
    echo "Session\LSDEnabled=true" >> "$CONFIG_FILE"
fi

# Añadir sección [AddTrackers] si no existe
if ! grep -q "\[AddTrackers\]" "$CONFIG_FILE"; then
    echo "" >> "$CONFIG_FILE"
    echo "[AddTrackers]" >> "$CONFIG_FILE"
    echo "Trackers=$TRACKERS_LIST" >> "$CONFIG_FILE"
fi

echo ""
echo "✅ Configuración aplicada exitosamente:"
echo "   - DHT habilitado"
echo "   - PeX (Intercambio de pares) habilitado"
echo "   - LSD (Descubrimiento local) habilitado"
echo "   - Lista de trackers automáticos añadida"
echo ""
echo "🔄 Reiniciando qBittorrent..."
docker compose --profile media restart qbittorrent

echo ""
echo "⏳ Esperando 15 segundos para que se reinicie..."
sleep 15

echo ""
echo "📋 Verificación de configuración:"
docker compose --profile media exec qbittorrent cat /config/qBittorrent/qBittorrent.conf | grep -E "(DHT|PeX|LSD|Trackers)" || echo "No se encontraron configuraciones esperadas"

echo ""
echo "🎯 Instrucciones para el usuario:"
echo "1. Accede a http://127.0.0.1:8080/"
echo "2. Para torrents existentes:"
echo "   - Selecciona los torrents lentos"
echo "   - Botón derecho > 'Trackers' > 'Agregar nuevos trackers'"
echo "   - Copia y pega esta lista de trackers:"
echo ""
echo "$TRACKERS_LIST" | head -10
echo ""
echo "3. Verifica en 'Opciones' → 'BitTorrent' que DHT, PeX y LSD estén activados"
echo ""
echo "💡 Consejos adicionales para mejor velocidad:"
echo "   - Verifica tu conexión a Internet"
echo "   - Asegúrate de no tener límites de ancho de banda configurados"
echo "   - Intenta descargar torrents populares con más semillas (seeders)"
echo ""
echo "🔄 Para revertir cambios:"
echo "   cp '$BACKUP_FILE' '$CONFIG_FILE'"
echo "   docker compose --profile media restart qbittorrent"