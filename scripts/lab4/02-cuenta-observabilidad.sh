#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
source config/.env

[ -n "${OPS_RO_PWD:-}" ] || {
  echo "Falta OPS_RO_PWD en config/.env"
  exit 2
}

if [[ ! "$OPS_RO_PWD" =~ ^[a-zA-Z0-9_]{16,}$ ]]; then
  echo "Usa al menos 16 caracteres: letras, numeros y guion bajo."
  exit 2
fi

{
  printf 'SET ECHO OFF VERIFY OFF\n'
  printf 'DEFINE ops_pwd = "%s"\n' "$OPS_RO_PWD"
  cat scripts/lab4/02-cuenta-observabilidad.sql
} | docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba
