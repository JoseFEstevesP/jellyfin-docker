# Jellyfin con Docker Compose

Despliegue local de la imagen oficial `jellyfin/jellyfin`, preparado para Fedora, Intel HD 520, biblioteca multimedia de solo lectura y un perfil opcional de HTTPS con Caddy.

## Configuración incluida

- Imagen oficial fijada a la versión estable `10.11.11`.
- Persistencia local de configuración, caché, fuentes y copias.
- Medios definidos por `MEDIA_PATH` y `MOVIES_PATH` en `.env`, montados en `/media/series` y `/media/peliculas` en solo lectura.
- Aceleración Intel mediante `/dev/dri/renderD128` y el grupo `render` (`GID 105`).
- Puerto web `8096/TCP` y descubrimiento local `7359/UDP`, ligados a la IP LAN configurada.
- Reinicio automático, parada limpia, `no-new-privileges` y rotación de logs.
- Caddy opcional para HTTPS y WebSockets.
- Script de copia de seguridad consistente con rotación y timer systemd semanal.
- `scripts/verify.sh` para comprobar el despliegue completo en un comando.

## Inicio

```bash
git clone git@github.com:JoseFEstevesP/jellyfin-docker.git
cd jellyfin-docker
cp .env.example .env
$EDITOR .env
docker compose config
docker compose pull
docker compose up -d
docker compose ps
```

En una instalación nueva, `MEDIA_PATH` y `MOVIES_PATH` deben existir y `PUID:PGID` debe coincidir con el propietario de `config/` y `cache/`. `create_host_path: false` evita que Docker cree rutas por error; comprueba también `getent group render` y `RENDER_GID` antes de iniciar.

En una instalación nueva, abre `http://<IP_DEL_SERVIDOR>:8096`, completa el asistente, crea un administrador con contraseña fuerte, añade las bibliotecas `/media/series` y `/media/peliculas` y desactiva el mapeo automático de puertos UPnP. Si cambia la IP de la red, actualiza `JELLYFIN_HTTP_BIND_ADDRESS` y `JELLYFIN_DISCOVERY_BIND_ADDRESS` en `.env`.

## Aceleración Intel

Comprueba que el contenedor ve la GPU:

```bash
docker compose exec jellyfin /usr/lib/jellyfin-ffmpeg/vainfo --display drm --device /dev/dri/renderD128
```

Compose solo expone la GPU. En esta instalación la aceleración ya está activa con **VA-API** en `config/config/encoding.xml`:

```bash
docker compose exec jellyfin /usr/lib/jellyfin-ffmpeg/ffmpeg -hide_banner \
  -init_hw_device vaapi=va:/dev/dri/renderD128 -f lavfi -i testsrc2=size=320x240 -t 1 \
  -vf format=nv12,hwupload -f null -
```

Si el contenedor se recrea y Jellyfin vuelve a la configuración por defecto, reactívala desde **Panel de control > Reproducción > Transcodificación** con **Intel VA-API** y el dispositivo `/dev/dri/renderD128`, códecs `h264`, `hevc` y `vc1`, y la opción de codificación por hardware activada. QSV también funciona con esta GPU, pero VA-API es la ruta más estable en Jellyfin.

La HD 520 es una GPU Skylake de sexta generación con capacidades limitadas: no esperes aceleración completa para HEVC de 10 bits.

## Copias de seguridad

Jellyfin 10.11.11 permite crear copias integradas desde **Panel de control > Copias de seguridad**. Para una copia manual y consistente de toda la configuración, ejecuta:

```bash
./scripts/backup.sh
```

El script se serializa con un lock, detiene Jellyfin, crea un archivo temporal, valida el archivo gzip, lo renombra atómicamente a `backups/jellyfin-config-AAAAMMDD-HHMMSS-nnnnnnnnn.tar.gz` con permisos privados y espera a que `/health` devuelva exactamente `Healthy`. Las copias contienen información sensible: guárdalas cifradas y fuera del disco del servidor.

Tras cada copia se eliminan las más antiguas y se conservan las `JELLYFIN_BACKUP_KEEP` más recientes (2 por defecto). Para cambiar la retención sin tocar la unidad:

```bash
systemctl --user edit --full jellyfin-backup.service
```

### Copia semanal automática

Las unidades de `systemd/` están instaladas en el gestor del usuario y se ejecutan los domingos a las 03:15 con un desfase aleatorio de hasta 15 minutos. `Persistent=true` recupera la copia si el equipo estaba apagado. `linger` está habilitado para que se ejecuten sin sesión abierta.

Las rutas de la unidad apuntan a `%h/jellyfin-docker`, la ubicación del clone. Si clonaste en otro directorio, ajusta `WorkingDirectory` y `ExecStart` con un override, sin modificar el archivo del repositorio:

```bash
mkdir -p ~/.config/systemd/user/jellyfin-backup.service.d
cat > ~/.config/systemd/user/jellyfin-backup.service.d/override.conf <<'EOF'
[Service]
WorkingDirectory=%h/ruta/real
ExecStart=
ExecStart=%h/ruta/real/scripts/backup.sh
EOF
systemctl --user daemon-reload
```

La línea `ExecStart=` vacía es obligatoria: sin ella el valor se añade al existente y systemd intenta ejecutar la ruta antigua, fallando con `203/EXEC`. Las condiciones como `ConditionPathExists` no admiten este reinicio y se combinan entre sí, así que no conviene añadirlas al override.

```bash
systemctl --user list-timers jellyfin-backup.timer
systemctl --user start jellyfin-backup.service
journalctl --user -u jellyfin-backup.service -n 50
```

Para deshabilitar la copia automática:

```bash
systemctl --user disable --now jellyfin-backup.timer
```

Para restaurar una copia, detén el servicio, conserva el directorio `config` actual, extrae el archivo sobre un directorio `config` vacío y mantén la misma versión de imagen con la que se creó la copia. Jellyfin no admite retrocesos de base de datos.

La restauración se verificó extrayendo la copia más reciente en un directorio temporal y comprobando que `jellyfin.db` supera `PRAGMA integrity_check`, que los XML son legibles y que se conservan la biblioteca, la aceleración por hardware y el asistente completado. Para repetir la comprobación sin tocar la configuración real:

```bash
archive="$(ls -1 backups/jellyfin-config-*.tar.gz | LC_ALL=C sort -r | head -n 1)"
tmp="$(mktemp -d)"
tar --extract --gzip --file "$archive" --directory "$tmp"
python3 -c "import sqlite3,sys; print(sqlite3.connect(f'file:{sys.argv[1]}?mode=ro', uri=True).execute('PRAGMA integrity_check').fetchone()[0])" "$tmp/config/data/jellyfin.db"
rm -rf "$tmp"
```

Las copias viven en el mismo almacenamiento que la configuración. Si el disco falla, ambas se pierden: copia `backups/` a un disco externo o NAS con `rsync -a --delete` o `restic`.

## Actualizaciones

Haz una copia antes de actualizar y cambia `JELLYFIN_IMAGE` en `.env` a la versión estable deseada. Después ejecuta:

```bash
docker compose pull jellyfin
docker compose up -d
docker compose logs --tail=100 jellyfin
```

La imagen está fijada a `10.11.11` para que el despliegue sea reproducible. Actualiza manualmente `JELLYFIN_IMAGE` a una versión estable verificada después de hacer una copia; no uses `latest` ni versiones `unstable` en producción.

## HTTPS opcional con Caddy

No redirijas el puerto `8096` directamente a Internet. Para acceso remoto usa una VPN o el proxy incluido:

1. Crea un dominio y apunta sus registros DNS A/AAAA al servidor.
2. Abre `80/TCP`, `443/TCP` y, opcionalmente para HTTP/3, `443/UDP` en el firewall.
3. Completa en `.env`:
   - `DOMAIN_NAME=jellyfin.ejemplo.com`
   - `JELLYFIN_PUBLISHED_SERVER_URL=https://jellyfin.ejemplo.com`
   - `JELLYFIN_HTTP_BIND_ADDRESS=127.0.0.1`
4. Inicia el perfil:

```bash
docker compose --profile https up -d
```

El perfil se niega a iniciar si falta `DOMAIN_NAME`, si `JELLYFIN_PUBLISHED_SERVER_URL` no usa `https://` o si `JELLYFIN_HTTP_BIND_ADDRESS` no es `127.0.0.1`; así el puerto Jellyfin no queda accesible sin cifrado fuera de Caddy.

5. Obtén la IP de Caddy y agrégala en **Panel de control > Red > Proxies conocidos** de Jellyfin:

```bash
docker compose --profile https ps -q caddy
docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$(docker compose --profile https ps -q caddy)"
```

Caddy no registra las URL completas de solicitudes para evitar exponer parámetros de autenticación en logs. El puerto UDP `7359` sigue configurado para descubrimiento en la LAN.

## Operación

```bash
./scripts/verify.sh
docker compose logs -f jellyfin
docker compose restart jellyfin
docker compose pull
docker compose up -d --remove-orphans
docker compose down
```

`scripts/verify.sh` comprueba en un solo comando la validity de `compose.yaml`, la sintaxis de los scripts, las unidades systemd, el estado y la salud del contenedor, la inicialización de VA-API, la aceleración configurada, la validez de la copia más reciente y que el timer esté habilitado. Devuelve código distinto de cero si algo falla, así que sirve como comprobación tras cualquier cambio.

Si Caddy está activo, usa el perfil en sus operaciones:

```bash
docker compose --profile https logs -f caddy
docker compose --profile https pull caddy
docker compose --profile https up -d
```

`docker compose down` no elimina los datos porque configuración, caché, fuentes y copias están en directorios locales. No uses `down -v` mientras el perfil Caddy esté activo, porque sus volúmenes contienen certificados y certificados de cuenta.

## Fuentes oficiales

- Contenedores: https://jellyfin.org/docs/general/installation/container/
- Aceleración Intel: https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/intel/
- Red y HTTPS: https://jellyfin.org/docs/general/post-install/networking/
- Copias y restauración: https://jellyfin.org/docs/general/administration/backup-and-restore/
- Unidades systemd de usuario: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
