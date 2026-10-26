#!/usr/bin/env bash
# Version 2 - Lab 4: autenticacion del SO, sin password en argumentos.
set -euo pipefail
source scripts/deployment/env/00-config.sh

[ $# -ge 1 ] || {
  echo "Uso: $0 <migracion> [migracion...] (nombre sin .sql)"
  exit 2
}

DEST="$EVID_LAB4/spool"
mkdir -p "$DEST"

for MIG in "$@"; do
  FILE="database/migrations/$MIG.sql"
  [ -f "$FILE" ] || {
    echo "ERROR: no existe $FILE"
    exit 2
  }
  LOG="$DEST/$(ts)_04-$MIG.spool.log"
  echo ">> Aplicando $MIG"

  if ! docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba \
    < "$FILE" 2>&1 | tee "$LOG"; then
    echo "ERROR en $MIG: revisa $LOG antes de continuar"
    exit 1
  fi
done

echo ">> Migraciones aplicadas. Evidencias en $DEST/"
