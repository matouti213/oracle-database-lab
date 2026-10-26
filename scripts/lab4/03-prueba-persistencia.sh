#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

echo "== 1. ANTES: entornos y datos =="
bash scripts/ops/sysdba.sh scripts/lab4/03-verificar-negocio.sql

echo "== 2. Parada limpia y borrado del contenedor =="
echo "Se conserva el volumen $VOL_NAME"
printf 'WHENEVER SQLERROR EXIT FAILURE\nSHUTDOWN IMMEDIATE;\nEXIT\n' \
  | docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba
docker stop -t 120 "$CONT_NAME" > /dev/null
docker rm "$CONT_NAME"
docker volume inspect "$VOL_NAME" --format '{{.Name}}'

echo "== 3. Recrear el contenedor =="
bash scripts/deployment/env/05-crear-contenedor.sh
bash scripts/ops/esperar-healthy.sh

echo "== 4. DESPUES: entornos y datos =="
bash scripts/ops/sysdba.sh scripts/lab4/03-verificar-negocio.sql

echo "== 5. Puertos publicados =="
docker port "$CONT_NAME"
