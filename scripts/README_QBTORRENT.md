# Optimización de qBittorrent para mejor velocidad

## Aplicación exitosa de la Opción A (trackers adicionales)

He creado varios scripts para optimizar qBittorrent. Los cambios principales aplicados:

### 1. Scripts creados:
- `configure_qbittorrent_trackers.sh` - Lista de trackers públicos
- `enable_dht_pex.sh` - Configura DHT, PeX y LSD (tuvo problemas)
- `fix_qbittorrent_config.sh` - Intento de modificar configuración
- `simple_qbittorrent_fix.sh` - Reemplazo completo del archivo de configuración
- `configure_qbittorrent_api.sh` - Instrucciones para configuración manual

### 2. Problema encontrado:
qBittorrent sobrescribe su archivo de configuración al reiniciarse, por lo que los cambios en `qBittorrent.conf` no persisten.

### 3. Solución recomendada (MANUAL):
**Configurar desde la interfaz web http://127.0.0.1:8080/**

#### Paso 1: Activar DHT, PeX y LSD
1. Ve a **Opciones** → **BitTorrent**
2. Marca estas casillas:
   - ✅ **Habilitar DHT** (red distribuida)
   - ✅ **Habilitar intercambio de pares (PeX)**
   - ✅ **Habilitar descubrimiento local de pares (LSD)**
3. Haz clic en **Aplicar**

#### Paso 2: Añadir trackers a torrents lentos
1. Selecciona los torrents con velocidad baja
2. Botón derecho → **Trackers** → **Agregar nuevos trackers**
3. Copia y pega esta lista:

```
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
```

#### Paso 3: Verificar conexión
- **Opciones** → **Conectividad** → Puerto **6881** (verifica que esté abierto)
- Considera activar **UPnP** si tu router lo soporta

## Diferencias clave con Freedownloadmanager

| Característica | qBittorrent | Freedownloadmanager |
|----------------|-------------|---------------------|
| **Tipo** | Cliente BitTorrent (P2P) | Gestor HTTP/FTP (descargas directas) |
| **Integración** | Se integra con Sonarr/Radarr | No tiene integración |
| **Velocidad** | Depende de semillas/peers | Depende del servidor HTTP |
| **Protocolo** | BitTorrent | HTTP, HTTPS, FTP |
| **Reemplazo** | ❌ No se puede reemplazar | ✅ Es para otro tipo de descargas |

## Consejos adicionales para velocidad

1. **Port Forwarding**: Configura el puerto 6881 en tu router
2. **Límites de ISP**: Algunos ISP limitan tráfico P2P
3. **Selección de torrents**: Elige torrents con más semillas (seeders)
4. **Horarios**: Prueba en diferentes horarios
5. **VPN**: Considera una VPN si tu ISP bloquea P2P

## Comandos útiles

```bash
# Ver estado de qBittorrent
docker compose --profile media ps qbittorrent

# Ver logs
docker compose --profile media logs qbittorrent

# Reiniciar
docker compose --profile media restart qbittorrent

# Ejecutar script de ayuda
./scripts/configure_qbittorrent_api.sh
```

**Nota**: La configuración manual desde la web es la más efectiva porque qBittorrent maneja su propio archivo de configuración internamente.