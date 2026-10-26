#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

echo "== 1. Procesos de background de FREE =="
PROCESOS=$(docker top "$CONT_NAME" -eo pid,user,rss,args)
printf '%s\n' "$PROCESOS" \
  | awk '/(ora|db)_[a-z0-9]+_FREE/ {n++; if(n<=15) print}
         END {print "Total de procesos de background:", n+0}'

echo "== 2. Procesos servidor y listener =="
docker top "$CONT_NAME" -eo pid,user,args \
  | awk '/oracleFREE|tnslsnr/ {print}'
echo "Puede no haber procesos servidor dedicados si no hay sesiones abiertas."

echo "== 3. Memoria del contenedor =="
docker stats --no-stream \
  --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' "$CONT_NAME"

echo "== 4. Archivos de la base en disco =="
docker exec "$CONT_NAME" bash -c '
  ls -lh /opt/oracle/oradata/FREE
  echo "-- FREEPDB1 --"
  ls -lh /opt/oracle/oradata/FREE/FREEPDB1
'

echo "== 5. Servicios registrados en el listener =="
docker exec "$CONT_NAME" lsnrctl status \
  | grep -E 'Service|Instance|Listening|Uptime'
