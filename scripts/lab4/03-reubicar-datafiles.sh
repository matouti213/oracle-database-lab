#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
DESTDIR="$DATA_ROOT/FREE/FREEPDB1"

sysdba() {
  docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba
}

echo "== 1. Datafiles pendientes de reubicar =="
LISTA=$(sysdba <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 400 TRIMOUT ON
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT tablespace_name || '|' || file_name FROM dba_data_files
WHERE tablespace_name LIKE 'TBS\_%' ESCAPE '\'
  AND file_name NOT LIKE '/opt/oracle/oradata/FREE/FREEPDB1/%'
ORDER BY tablespace_name;
EXIT
SQL
)
LISTA=$(printf '%s\n' "$LISTA" | sed '/^[[:space:]]*$/d')

if [ -z "$LISTA" ]; then
  echo "Nada que reubicar: ya están todos en $DESTDIR"
else
  echo "$LISTA"
  while IFS='|' read -r TBS ORIG; do
    NUEVO="$DESTDIR/$(basename "$ORIG")"

    # Evitar sobrescribir un destino de un intento anterior.
    if docker exec "$CONT_NAME" test -e "$NUEVO"; then
      echo "ERROR: ya existe $NUEVO. Revisar antes de continuar."
      exit 1
    fi

    echo "== 2. $TBS: $ORIG -> $NUEVO =="
    echo "a) Tablespace OFFLINE"
    sysdba <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER TABLESPACE $TBS OFFLINE NORMAL;
EXIT
SQL

    echo "b) Copia física conservando permisos"
    docker exec "$CONT_NAME" cp -p "$ORIG" "$NUEVO"

    echo "c) Nueva ruta, ONLINE y límite de crecimiento"
    sysdba <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER TABLESPACE $TBS RENAME DATAFILE '$ORIG' TO '$NUEVO';
ALTER TABLESPACE $TBS ONLINE;
ALTER DATABASE DATAFILE '$NUEVO' AUTOEXTEND ON NEXT 50M MAXSIZE 1G;
EXIT
SQL

    echo "d) Operación correcta: retirar el original"
    docker exec "$CONT_NAME" rm -f "$ORIG"
  done <<< "$LISTA"
fi

echo "== 3. Resultado =="
sysdba <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET LINESIZE 220 PAGESIZE 50 FEEDBACK OFF
COLUMN tablespace_name FORMAT A16
COLUMN file_name FORMAT A65
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT tablespace_name, file_name, status, autoextensible,
       ROUND(bytes / 1048576) AS mb,
       ROUND(maxbytes / 1048576) AS max_mb
FROM dba_data_files
WHERE tablespace_name LIKE 'TBS\_%' ESCAPE '\'
ORDER BY tablespace_name;
EXIT
SQL
