# Manual de operación

Guía de uso diario del stack `media`. El [README](README.md) explica la instalación, la accélulación por hardware, las copias de seguridad y el HTTPS; este documento explica **cómo conseguir y verificar contenido una vez que todo está montado**.

## Qué hace cada pieza

```
Seerr (5055)          Pides una película o serie
   ↓
Sonarr (8989) /       Deciden qué release exacto descargar
Radarr (7878)
   ↓
Prowlarr (9696)       Prueba los indexadores y devuelve los resultados
   ↓
qBittorrent (8080)    Descarga a DOWNLOADS_PATH
   ↓
Sonarr / Radarr       Al terminar, hardlink del archivo a la biblioteca
   ↓
Jellyfin (8096)       Lo indexa y aparece en la tele y los móviles
```

Cada paso es independiente: si Sonarr no encuentra nada, el problema nunca está en qBittorrent, y si Jellyfin no muestra el título, el problema está antes.

## Pedir una película o una serie

1. Abre `http://127.0.0.1:5055` (túndel SSH activo, ver [README](README.md#acceso-remoto-por-túnel-ssh)).
2. Busca el título en Discover y pulsa **Request**.
3. Seerr se encarga del resto. No necesitas abrir Sonarr ni Radarr: la serie o la película se crea, se busca y se descarga sola.

Para elegir tú el release, ve al buscador interactivo de Sonarr o Radarr (**Series > la serie > Episodes > Search**, o **Movies > la película > Search**), ordena por *Seeders* y pulsa **Grab** sobre uno concreto.

## Verificar una descarga

La descarga vive en **dos rutas distintas** y conviene distinguirlas:

| Estado | Ruta |
| --- | --- |
| Descargando (parcial) | `/home/gato99/Vídeos/torrents/<release>/` |
| Terminado (biblioteca) | `/home/gato99/Vídeos/series/<serie>/Season NN/` o `/home/gato99/Vídeos/peliculas/<peli>/` |

Un archivo en curso puede llevar el sufijo `.!qB`, pero solo si qBittorrent tiene activada la opción de conservarlos aparte; en este despliegue los parciales mantienen su nombre real. La señal fiable es que **el tamaño del archivo crece** y el torrent no llega al 100 %.

```bash
# tamaño de lo descargado, refrescado cada 3 s
watch -n3 'du -sh /home/gato99/Vídeos/torrents/*/'

# qué hay descargándose ahora
ls -la /home/gato99/Vídeos/torrents/*/
```

Desde las interfaces, qBittorrent muestra la barra de progreso por torrent y Sonarr muestra el estado por episodio en **Activity > Queue**.

Los datos van primero a `torrents/` y al completarse Sonarr crea un **hardlink** en `series/`. El archivo ocupa espacio una sola vez, la importación es inmediata y el seed sigue vivo aunque borres la copia de la biblioteca.

## Cuánto ocupa

Un pack de temporada pesa mucho más que lo que sugiere el título: 13 episodios en BD 1080p HEVC ocupan del orden de **30 GB**. Antes de agarrar un pack, mira el tamaño en el buscador. Con anime conviene un perfil de calidad propio en Sonarr que limite a `1080p`.

## Indexadores

Configurados en Prowlarr y compartidos con Sonarr y Radarr:

| Indexador | Estado | Notas |
| --- | --- | --- |
| Nyaa | Funciona | Solo anime. La opción más fiable del lote |
| Anime Tosho | Funciona | Anime en español |
| Bangumi Moe | Funciona | Anime |
| SubsPlease | Funciona | Subtitulado, anime |
| Mikan | Funciona | Anime; rips en chino |
| Internet Archive | Intermitente | Timeouts y `429 Too Many Requests`; sin semillas útiles |
| LinuxTracker | Funciona | Linux, no contenido multimedia |
| EZTV | No disponible | Cloudflare bloquea `eztvx.to` |
| 1337x, Anidex, YTS | No disponibles | `403`, `403` y sin respuesta |

**Limitación real**: con indexadores públicos solo, la cobertura de **anime** es buena y la de **películas occidentales es mala**. Nyaa no devuelve nada útil para una película reciente y los trackers de películas generalistas están bloqueados o cerrados. Para películas terrestres necesitarás un tracker privado con cuenta; no se puede añadir sin credenciales. Internet Archive es el único que sigue funcionando, y solo con material viejo o poco demandado.

## Borrar cosas correctamente

Son tres acciones distintas y no son intercambiables:

| Quiero... | Dónde |
| --- | --- |
| Cancelar una descarga en curso | qBittorrent > torrent > **Delete**, con *Delete files* marcado |
| Quitar un título de la biblioteca | Sonarr/Radarr > el título > **Delete**, y decide si borrar archivos |
| Quitar la serie de la app | Igual, pero ojo: en Sonarr, borrar la serie **no** siempre borra el torrent ya descargado |

Al borrar un torrent con *Delete files*, comprueba que la carpeta desapareció de `torrents/`; a veces qBittorrent la deja un instante:

```bash
ls -1 /home/gato99/Vídeos/torrents/
```

Un torrent que sigue sembrando ocupa espacio. Si no te interesa sembrar, quítale prioritariamente los packs de temporada completa.

## Trampas conocidas

Estas cosas ocuparon tiempo y conviene recordarlas:

- **`MissingEpisodeSearch` es global.** El `seriesId` que le mandes en el cuerpo del comando se ignora y busca en *toda* la librería. Para una sola serie usa `SeriesSearch` con su `seriesId`, o hazlo desde la UI. Un `MissingEpisodeSearch` mal lanzado puede agarrar temporadas completas de otras series.
- **Añadir una serie por API no monitoriza sus episodios.** La serie queda `monitored=True` pero cada episodio sigue en `monitored=False`, y entonces toda búsqueda devuelve cero resultados y parece que el indexador falla. Hay que monitorizar los episodios explícitamente.
- **Los packs de anime se cuelan en la numeración.** Al ser series con temporadas, specials (`Season 0`) y numeración absoluta, un pack puede mapear a varios episodios. Revisa *Seeders* y tamaño antes de agarrar.
- **La API de Sonarr v4 no tiene `id` numérico en los releases**, solo `guid`, y `POST /api/v3/release/{guid}` devuelve `405`. Para agarres manuales, usa la UI.
- **`POST /api/v1/applications/{id}/sync` en Prowlarr devuelve `405`.** La sincronización de indexadores es automática; no hace falta forzarlla.
- **qBittorrent 5.x rechaza guardar la ruta por API**: `setPreferences` devuelve `400 Bad Request`. Deja el contenedor parado y edita `config/qbittorrent/qBittorrent/qBittorrent.conf`, en `Downloads\SavePath` y `Downloads\TempPath`.
- **El bind de `.env` puede no ser el real.** Si cambias una dirección, `docker compose ps` y `docker inspect` muestran lo realmente publicado; recrea solo el servicio afectado.
- **Anime necesita su propio tipo de serie** en Sonarr (*Anime*) porque usa otra convención de nombres y de numeración que las series normales.

## Diagnóstico rápido

| Síntoma | Causa probable | Dónde mirar |
| --- | --- | --- |
| Seerr no encuentra nada | Índice de TMDB sin resultados, o caché sin refrescar | Search > *Update* en Seerr |
| Sonarr no encuentra releases | Episodios sin monitorizar, o índice vacío | Prowlarr > indexador > *Test* |
| La búsqueda devuelve `0` | Episodios en `monitored=False` | Sonarr > Series > Episodes |
| Aviso de fallo de hardlink | `chattr +C` en `torrents`, o ruta de guardado distinta de `/media/torrents` | `lsattr -d "$DOWNLOADS_PATH"`, Preferencias de qBittorrent |
| Aviso de `Cross-device link` | Montajes separados para descargas y biblioteca | `compose.yaml`, montajes de `/media` |
| Jellyfin no ve un título nuevo | No se ha reescaneado la biblioteca | Sonarr > *Refresh Series*, o Jellyfin > Biblioteca > *Scan All* |
| La importación se queda pendiente | La copia parcial no ha terminado | qBittorrent: el torrent no llega al 100 % |

## Mantenimiento

```bash
./scripts/verify.sh                              # comprobación integral
docker compose --profile media logs -f sonarr   # seguir una importación
docker compose --profile media restart qbittorrent
```

`verify.sh` es la primera herramienta cuando algo va mal: valida `compose.yaml`, los scripts, las unidades systemd, la salud de los contenedores, la aceleración por hardware, la copia más reciente y que el timer esté activo. Devuelve código distinto de cero si algo falla.