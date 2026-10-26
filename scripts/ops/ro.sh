#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
source config/.env

SQL_FILE="${1:?Uso: ro.sh <archivo.sql> [servicio]}"
SERVICE="${2:-FREE}"

[ -f "$SQL_FILE" ] || {
  echo "No existe $SQL_FILE"
  exit 2
}
[ -n "${OPS_RO_PWD:-}" ] || {
  echo "Falta OPS_RO_PWD en config/.env"
  exit 2
}

{
  printf 'SET ECHO OFF VERIFY OFF\n'
  printf 'WHENEVER OSERROR EXIT FAILURE\n'
  printf 'WHENEVER SQLERROR EXIT FAILURE\n'
  printf 'CONNECT c##ops_ro/"%s"@//localhost:%s/%s\n' \
    "$OPS_RO_PWD" "$PORT_DB" "$SERVICE"
  printf '@%s\nEXIT\n' "$SQL_FILE"
} | sql -S -L /nolog
