#!/usr/bin/env bash
# Version 2 - Lab 4
set -euo pipefail
source scripts/deployment/env/00-config.sh

if docker ps -a --format '{{.Names}}' | grep -qx "$CONT_NAME"; then
  echo "El contenedor $CONT_NAME ya existe; no se crea de nuevo."
  docker ps -a --filter "name=$CONT_NAME"
  exit 0
fi

if docker run --rm -v "$VOL_NAME":/datos "$HELPER_IMG" \
  test -d /datos/FREE; then
  echo "El volumen contiene FREE: se reutiliza sin contraseñas."
  docker run -d --name "$CONT_NAME" \
    -p "$PORT_DB":1521 \
    -v "$VOL_NAME":/opt/oracle/oradata \
    "$IMG"
else
  echo "Volumen vacío: primera creación de la base."
  set -a
  source config/.env
  set +a
  docker run -d --name "$CONT_NAME" \
    -p "$PORT_DB":1521 \
    -e ORACLE_PWD="$ORACLE_PWD" \
    -v "$VOL_NAME":/opt/oracle/oradata \
    "$IMG"
fi

echo "Contenedor $CONT_NAME creado."
docker ps --filter "name=$CONT_NAME"
