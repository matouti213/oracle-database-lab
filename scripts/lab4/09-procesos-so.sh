#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

docker exec -i "$CONT_NAME" bash -s > "$TMP" <<'SH'
printf "%-8s %-10s %s\n" PID RSS_MB PROCESO
for d in /proc/[0-9]*; do
  pid=${d#/proc/}
  cmd=$(tr '\0' ' ' < "$d/cmdline" 2>/dev/null) || continue
  [ -n "$cmd" ] || continue
  rss=$(awk '/^VmRSS/ {printf "%.0f", $2/1024}' "$d/status" 2>/dev/null)
  printf "%-8s %-10s %s\n" "$pid" "${rss:-0}" "$cmd"
done
SH

echo "== 1. Procesos de background clave =="
awk 'NR == 1 || /_(pmon|lreg|smon|dbw0|lgwr|ckpt|mmon|mmnl|reco)_/' "$TMP"

echo "== 2. Recuento por tipo =="
awk '
  $3 ~ /^(db|ora)_[a-z0-9]+_FREE$/ {bg++}
  $3 ~ /^oracleFREE/ {srv++}
  $3 ~ /tnslsnr$/ {lst++}
  END {
    print "Background:", bg+0
    print "Servidor dedicado:", srv+0
    print "Listener:", lst+0
  }
' "$TMP"

echo "== 3. Procesos servidor =="
awk '$3 ~ /^oracleFREE/ {print; n++}
     END {if (!n) print "Ninguno en este momento."}' "$TMP"

if [ -n "${1:-}" ]; then
  echo "== 4. Proceso con SPID $1 =="
  awk -v p="$1" '$1 == p {print; n++}
    END {if (!n) print "PID no encontrado; comprobar si la instancia se reinicio."}' "$TMP"
fi
