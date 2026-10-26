#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

echo "== A. Vista SQL =="
docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba \
  < scripts/lab4/01-diagnostico-inicial.sql

echo
echo "== B. Vista del sistema de archivos =="
docker exec -i "$CONT_NAME" bash -s <<'SH'
set -euo pipefail
echo "ORACLE_SID=$ORACLE_SID ORACLE_HOME=$ORACLE_HOME"

sqlplus -s -L / as sysdba <<'SQL' > /tmp/negocio.lst
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 300 TRIMOUT ON
SELECT d.name FROM v$datafile d JOIN v$pdbs p ON p.con_id = d.con_id
WHERE p.name = 'FREEPDB1'
  AND d.name LIKE '%01.dbf'
  AND d.name NOT LIKE '%/FREEPDB1/%';
EXIT
SQL

if [ ! -s /tmp/negocio.lst ]; then
  echo "Todos los datafiles están en su carpeta estándar."
fi

while read -r f; do
  [ -n "$f" ] || continue
  real=$(readlink -f "$f")
  case "$real" in
    /opt/oracle/oradata/*)
      echo "DENTRO del volumen, pero en carpeta no estándar: $f -> $real"
      ;;
    *)
      echo "FUERA del volumen: $f -> $real"
      ;;
  esac
done < /tmp/negocio.lst

echo "-- Contenido de ORACLE_HOME/dbs --"
ls -l "$ORACLE_HOME/dbs"
SH
