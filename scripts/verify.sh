#!/usr/bin/env bash
set -Eeuo pipefail

project_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
failures=0

pass() {
  printf 'OK    %s\n' "$1"
}

fail() {
  printf 'FALLA %s\n' "$1" >&2
  failures=$((failures + 1))
}

check_compose() {
  if docker compose --project-directory "$project_dir" config -q 2>/dev/null; then
    pass 'compose.yaml es valido'
  else
    fail 'compose.yaml no es valido'
  fi
}

check_scripts() {
  local script
  local ok=true

  while IFS= read -r script; do
    bash -n "$script" || ok=false
  done < <(find "${project_dir}/scripts" "${project_dir}/systemd" -maxdepth 1 -type f -name '*.sh' | LC_ALL=C sort)

  if [[ "$ok" == "true" ]]; then
    pass 'sintaxis de los scripts'
  else
    fail 'sintaxis de los scripts'
  fi
}

check_units() {
  local unit
  local output
  local errors

  for unit in "${project_dir}"/systemd/*.service "${project_dir}"/systemd/*.timer; do
    [[ -e "$unit" ]] || continue
    output="$(systemd-analyze verify "$unit" 2>&1 || true)"
    errors="$(printf '%s\n' "$output" | grep -v 'is not executable' | grep -v '^$' || true)"
    if [[ -z "$errors" ]]; then
      pass "unidad valida: $(basename "$unit")"
    else
      fail "unidad invalida: $(basename "$unit")"
      printf '%s\n' "$errors" >&2
    fi
  done
}

check_container() {
  local container_id
  local state

  container_id="$(docker compose --project-directory "$project_dir" ps -q jellyfin)"
  if [[ -z "$container_id" ]]; then
    fail 'el contenedor jellyfin no existe'
    return
  fi

  state="$(docker inspect --format '{{.State.Status}}' "$container_id")"
  if [[ "$state" == "running" ]]; then
    pass 'el contenedor jellyfin esta en ejecucion'
  else
    fail "el contenedor jellyfin esta en estado ${state}"
  fi
}

check_health() {
  local endpoint
  local response

  endpoint="$(docker compose --project-directory "$project_dir" port jellyfin 8096 2>/dev/null || true)"
  if [[ -z "$endpoint" ]]; then
    endpoint="127.0.0.1:8096"
  fi

  response="$(curl --noproxy '*' --connect-timeout 2 --max-time 5 --fail --silent --show-error "http://${endpoint}/health" 2>/dev/null || true)"
  if [[ "$response" == "Healthy" ]]; then
    pass "/health responde Healthy en ${endpoint}"
  else
    fail "/health no responde Healthy en ${endpoint} (respuesta: '${response}')"
  fi
}

check_gpu() {
  local output

  if [[ ! -e "${RENDER_DEVICE:-/dev/dri/renderD128}" ]]; then
    output="$(docker compose --project-directory "$project_dir" exec -T jellyfin sh -c 'ls -1 /dev/dri/' 2>&1 || true)"
    printf '%s\n' "$output" >&2
    fail 'no hay dispositivo de render DRI en el contenedor'
    return
  fi

  output="$(docker compose --project-directory "$project_dir" exec -T jellyfin \
    /usr/lib/jellyfin-ffmpeg/ffmpeg -hide_banner -loglevel error \
    -init_hw_device vaapi=va:/dev/dri/renderD128 -f lavfi -i testsrc2=size=64x64 -t 1 \
    -vf format=nv12,hwupload -f null - 2>&1 || true)"

  if [[ -z "$output" ]]; then
    pass 'VAAPI inicializa en /dev/dri/renderD128'
  else
    printf '%s\n' "$output" >&2
    fail 'VAAPI no pudo inicializar'
  fi
}

check_hwa_config() {
  local encoding_file="${project_dir}/config/config/encoding.xml"
  local accel

  if [[ ! -f "$encoding_file" ]]; then
    fail "falta ${encoding_file}"
    return
  fi

  accel="$(python3 -c "import xml.etree.ElementTree as ET,sys; print(ET.parse(sys.argv[1]).getroot().findtext('HardwareAccelerationType'))" "$encoding_file" 2>/dev/null || true)"
  if [[ -z "$accel" || "$accel" == "none" ]]; then
    fail "aceleracion por hardware desactivada (valor: '${accel:-ilegible}')"
  else
    pass "aceleracion por hardware: ${accel}"
  fi
}

check_backups() {
  local newest

  newest="$(find "${project_dir}/backups" -maxdepth 1 -type f -name 'jellyfin-config-*.tar.gz' -printf '%f\n' 2>/dev/null | LC_ALL=C sort -r | head -n 1 || true)"
  if [[ -z "$newest" ]]; then
    fail 'no hay copias de seguridad'
    return
  fi

  if tar --list --gzip --file "${project_dir}/backups/${newest}" >/dev/null 2>&1; then
    pass "copia mas reciente valida: ${newest}"
  else
    fail "copia corrupta: ${newest}"
  fi
}

check_timer() {
  if systemctl --user is-enabled jellyfin-backup.timer >/dev/null 2>&1; then
    pass 'timer semanal de copias habilitado'
  else
    fail 'timer semanal de copias no habilitado'
  fi
}

check_compose
check_scripts
check_units
check_container
check_health
check_gpu
check_hwa_config
check_backups
check_timer

if (( failures > 0 )); then
  printf '\n%d comprobacion(es) fallida(s).\n' "$failures" >&2
  exit 1
fi

printf '\nTodas las comprobaciones pasaron.\n'
