#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
SQL_FILE="${1:?Uso: sysdba.sh <archivo.sql>}"
[ -f "$SQL_FILE" ] || {
  echo "No existe $SQL_FILE"
  exit 2
}
docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba < "$SQL_FILE"
