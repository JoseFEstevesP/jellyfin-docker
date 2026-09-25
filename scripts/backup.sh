#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

project_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
timestamp="$(date +%Y%m%d-%H%M%S-%N)"
archive="${project_dir}/backups/jellyfin-config-${timestamp}.tar.gz"
keep="${JELLYFIN_BACKUP_KEEP:-2}"
container_id=""
temp_archive=""
was_running=false

if ! [[ "$keep" =~ ^[0-9]+$ ]] || (( keep < 1 )); then
  printf 'JELLYFIN_BACKUP_KEEP debe ser un entero mayor o igual a 1, recibido: %s\n' "$keep" >&2
  exit 2
fi

mkdir -p "${project_dir}/backups"
exec 9>"${project_dir}/backups/.backup.lock"
if ! flock -n 9; then
  printf '%s\n' 'Ya hay una copia de seguridad en ejecución.' >&2
  exit 1
fi

wait_for_jellyfin() {
  local attempt
  local published_endpoint

  published_endpoint="$(docker compose --project-directory "$project_dir" port jellyfin 8096 2>/dev/null || true)"
  if [[ -z "$published_endpoint" ]]; then
    published_endpoint="127.0.0.1:8096"
  fi

  for attempt in {1..60}; do
    response="$(curl --noproxy '*' --connect-timeout 2 --max-time 5 --fail --silent --show-error "http://${published_endpoint}/health" 2>/dev/null || true)"
    if [[ "$response" == "Healthy" ]]; then
      return 0
    fi
    sleep 2
  done

  return 1
}

cleanup() {
  local exit_code=$?

  if [[ -n "$temp_archive" ]]; then
    rm -f -- "$temp_archive"
  fi

  if [[ "$was_running" == "true" ]]; then
    if ! docker compose --project-directory "$project_dir" up -d --wait --wait-timeout 180 jellyfin || ! wait_for_jellyfin; then
      printf 'No se pudo reiniciar Jellyfin correctamente.\n' >&2
      exit_code=1
    fi
  fi

  exit "$exit_code"
}

prune_old_backups() {
  local stale
  local total
  local -a stale_names

  mapfile -t stale_names < <(
    find "${project_dir}/backups" -maxdepth 1 -type f -name 'jellyfin-config-*.tar.gz' -printf '%f\n' \
      | LC_ALL=C sort -r \
      | tail -n "+$((keep + 1))"
  )

  total="${#stale_names[@]}"
  if (( total == 0 )); then
    return 0
  fi

  for stale in "${stale_names[@]}"; do
    rm -f -- "${project_dir}/backups/${stale}"
  done

  printf 'Copias antiguas eliminadas: %d (se conservan %d)\n' "$total" "$keep"
}

trap cleanup EXIT

container_id="$(docker compose --project-directory "$project_dir" ps -q jellyfin)"
if [[ -n "$container_id" ]] && [[ "$(docker inspect --format '{{.State.Running}}' "$container_id")" == "true" ]]; then
  was_running=true
  docker compose --project-directory "$project_dir" stop jellyfin
fi

temp_archive="$(mktemp --tmpdir="${project_dir}/backups" .jellyfin-config.XXXXXX)"
tar --create --gzip --file "$temp_archive" --directory "$project_dir" config
tar --list --gzip --file "$temp_archive" >/dev/null
mv -- "$temp_archive" "$archive"
temp_archive=""
chmod 600 "$archive"
printf 'Copia creada: %s\n' "$archive"
prune_old_backups
