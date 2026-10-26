#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

DEST="$EVID_LAB4/config"
mkdir -p "$DEST"

for f in initFREE_lab4.ora initFREE_lab4_memoria.ora; do
  docker cp "$CONT_NAME:/tmp/$f" "$DEST/$f"
done

echo "== Numero de lineas de cada PFILE =="
wc -l "$DEST"/initFREE_lab4*.ora

nombres() {
  grep -oE '^([*A-Za-z0-9]+\.)?[a-z][a-z0-9_]*=' "$1" \
    | sed -E 's/^.*\.//; s/=$//' \
    | LC_ALL=C sort -u
}

echo "== Parametros en MEMORIA no escritos en el SPFILE =="
LC_ALL=C comm -13 \
  <(nombres "$DEST/initFREE_lab4.ora") \
  <(nombres "$DEST/initFREE_lab4_memoria.ora") \
  | paste -sd " " \
  | fold -s -w 120
