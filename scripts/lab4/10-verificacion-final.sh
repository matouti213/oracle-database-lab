#!/usr/bin/env bash
set -uo pipefail
source scripts/deployment/env/00-config.sh
fallos=0

ok() { printf '[OK] %s\n' "$1"; }
fallo() {
  printf '[FALLO] %s\n' "$1"
  fallos=$((fallos + 1))
}
comprobar() {
  if [ "$2" = "$3" ]; then
    ok "$1 ($2)"
  else
    fallo "$1: hay '$2'; se esperaba '$3'"
  fi
}

if ! VALORES=$(docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT FAILURE
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 200 TRIMOUT ON
SELECT 'open_mode=' || open_mode FROM v$database;
SELECT 'pdb=' || open_mode FROM v$pdbs WHERE name = 'FREEPDB1';
SELECT 'open_cursors=' || value FROM v$parameter WHERE name = 'open_cursors';
SELECT 'db_files_spfile=' || isspecified FROM v$spparameter
WHERE name = 'db_files' AND sid = '*';
SELECT 'ops_ro=' || common FROM cdb_users
WHERE username = 'C##OPS_RO' AND con_id = 1;
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT 'fuera_de_carpeta=' || COUNT(*) FROM dba_data_files
WHERE tablespace_name LIKE 'TBS\_%' ESCAPE '\'
AND file_name NOT LIKE '/opt/oracle/oradata/FREE/FREEPDB1/%';
SELECT 'tbs_negocio=' || COUNT(*) FROM dba_tablespaces
WHERE tablespace_name LIKE 'TBS\_%' ESCAPE '\';
SELECT 'con_password=' || COUNT(*) FROM dba_users
WHERE username LIKE 'ADMIN\_%' ESCAPE '\'
AND authentication_type <> 'NONE';
SELECT 'v002=' ||
(SELECT COUNT(*) FROM admin_academia.aca_estudiantes) || '/' ||
(SELECT COUNT(*) FROM admin_academia.aca_asignaturas) || '/' ||
(SELECT COUNT(*) FROM admin_academia.aca_matriculas) FROM dual;
EXIT
SQL
); then
  printf '%s\n' "$VALORES"
  echo "[FALLO] No se pudo completar la consulta SQL."
  exit 1
fi

val() {
  printf '%s\n' "$VALORES" | sed -n "s/^$1=//p" | tr -d '[:space:]'
}

echo "== Respaldo =="
BK=$(find backups -mindepth 1 -maxdepth 1 -type d \
  -name '*_lab3-final' | sort | tail -n 1)
if [ -n "$BK" ] && (cd "$BK" && sha256sum --check --quiet SHA256SUMS); then
  ok "Backup integro: $BK"
else
  fallo "No hay backup lab3-final integro"
fi

echo "== Correcciones y datos =="
comprobar "Tablespaces de negocio" "$(val tbs_negocio)" 5
comprobar "Datafiles fuera de carpeta estandar" "$(val fuera_de_carpeta)" 0

if FUERA=$(docker exec -i "$CONT_NAME" bash -s <<'SH'
set -euo pipefail
n=0
for f in /opt/oracle/oradata/FREE/FREEPDB1/*.dbf; do
  r=$(readlink -e "$f")
  case "$r" in
    /opt/oracle/oradata/*) ;;
    *) n=$((n + 1)) ;;
  esac
done
echo "$n"
SH
); then
  comprobar "Archivos cuya ruta real sale del volumen" "$FUERA" 0
else
  fallo "No se pudieron comprobar las rutas reales"
fi

comprobar "Cuentas ADMIN con autenticacion distinta de NONE" "$(val con_password)" 0
comprobar "Estudiantes/asignaturas/matriculas" "$(val v002)" "20000/40/60000"

if PUERTOS=$(docker port "$CONT_NAME"); then
  if [[ "$PUERTOS" == *8181* ]]; then
    fallo "El puerto 8181 sigue publicado"
  else
    ok "8181 no se publica"
  fi
else
  fallo "No se pudieron consultar los puertos"
fi

echo "== Instancia y parametros =="
comprobar "CDB abierta" "$(val open_mode)" READWRITE
comprobar "FREEPDB1 abierta" "$(val pdb)" READWRITE
comprobar "C##OPS_RO comun" "$(val ops_ro)" YES
comprobar "open_cursors restaurado" "$(val open_cursors)" 300
comprobar "db_files sin cambio pendiente" "$(val db_files_spfile)" FALSE

echo "== Evidencias y Git =="
shopt -s nullglob
for n in 00 01 02 03 04 05 06 07 08 09; do
  archivos=("$EVID_LAB4"/*/*_"$n"-*)
  if [ "${#archivos[@]}" -gt 0 ]; then
    ok "Evidencia $n"
  else
    fallo "Falta evidencia $n"
  fi
done

for f in initFREE_lab4.ora initFREE_lab4_memoria.ora; do
  if git ls-files --error-unmatch "$EVID_LAB4/config/$f" >/dev/null 2>&1; then
    ok "PFILE en Git: $f"
  else
    fallo "PFILE no versionado: $f"
  fi
done

if git ls-files --error-unmatch config/.env >/dev/null 2>&1; then
  fallo "config/.env esta en Git"
else
  ok "config/.env fuera de Git"
fi

if [ -z "$(git ls-files -- backups/)" ]; then
  ok "backups/ fuera de Git"
else
  fallo "Hay backups en Git"
fi

echo
if [ "$fallos" -eq 0 ]; then
  echo "RESULTADO: TODO OK en las comprobaciones tecnicas."
else
  echo "RESULTADO: $fallos FALLO(S)."
fi
exit "$fallos"
