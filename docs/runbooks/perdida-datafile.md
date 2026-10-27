# Runbook — pérdida de un datafile de aplicación

**Entorno validado:** Oracle Free, contenedor `oralab-26ai`, CDB `FREE`, PDB `FREEPDB1`.  
**Caso probado:** TBS_ACADEMIA, datafile 16, `/opt/oracle/oradata/FREE/FREEPDB1/academia01.dbf`.  
**Autor:** Amine · Lab 5, Issue #9 · 27/10/2026.

## Objetivo y límites

Restaurar un datafile de aplicación perdido y aplicar redo hasta recuperar los cambios confirmados. Este procedimiento no es para perder SYSTEM, UNDO activo, toda la base o todos los control files. No ejecutar el script de simulacro 14d durante un incidente real: ese script borra deliberadamente un archivo.

En la prueba, Oracle cerró FREEPDB1 por ORA-63999: la reparación se hizo con la PDB MOUNTED, manteniendo la instancia abierta. La recuperación tardó 7 s desde el comienzo de reparación y 8 s desde el fallo. La fila 104, confirmada después del backup, sobrevivió: RPO observado 0.

## 1. Diagnóstico sin destruir nada

Guardar hora de fallo/detección y salidas; mantener los logs fuera del volumen que se repara. Desde Ubuntu:

```bash
cd ~/oracle-database-lab
source scripts/deployment/env/00-config.sh
mkdir -p "$EVID_LAB5/script"
docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 100
COLUMN name FORMAT A85
SELECT log_mode, open_mode FROM v$database;
SELECT name, open_mode FROM v$pdbs;
SELECT d.file#, d.con_id, t.name AS tablespace_name, d.name, d.status
FROM v$datafile d JOIN v$tablespace t
 ON t.ts#=d.ts# AND t.con_id=d.con_id
WHERE t.name='TBS_ACADEMIA';
SELECT file#, online_status, error, change# FROM v$recover_file;
SELECT file#, con_id, status, error, recover FROM v$datafile_header;
EXIT
SQL
```

Leer el alert log y correlacionar ORA-01116/01110/27041 con la ruta y el identificador. No deducir el archivo solo por el número de un error antiguo. En esta práctica el 25 es TiendaSur y el 16 ACADEMIA. La consulta final adicional confirmó ambos ONLINE y ningún archivo pendiente de recuperación.

## 2. Verificar la posibilidad de recuperar

Se requieren una copia válida previa a la pérdida y redo suficiente para alcanzar el estado deseado. La FRA debe tener espacio y el destino físico debe estar disponible. ARCHIVELOG por sí solo no garantiza que se conserven todos los logs necesarios. No borrar archivados ni piezas RMAN para liberar espacio durante esta recuperación.

Los ejemplos siguientes usan **16**, el identificador verificado en este laboratorio; sustituirlo únicamente tras identificar el archivo del incidente. Comprobar las copias desde Ubuntu:

```bash
docker exec -i oralab-26ai rman target / <<'RMAN'
LIST BACKUP OF DATAFILE 16;
RESTORE DATAFILE 16 VALIDATE;
RMAN
```

Si no existe copia utilizable o faltan logs, detener el procedimiento y evaluar las alternativas y su pérdida de datos; no ejecutar OPEN RESETLOGS por ensayo. La validación de piezas no garantiza por sí sola que exista toda la cadena de redo necesaria.

## 3. Aislar el archivo o esperar a la PDB montada

Si FREEPDB1 sigue READ WRITE, poner el datafile fuera de línea:

```bash
docker exec -i oralab-26ai sqlplus -s -L / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT FAILURE
ALTER SESSION SET CONTAINER=FREEPDB1;
ALTER DATABASE DATAFILE 16 OFFLINE;
EXIT
SQL
```

Si Oracle ya cerró la PDB por fallo de medio, confirmar desde CDB$ROOT que está **MOUNTED** antes de lanzar RMAN. No ejecutar restauración mientras el cierre está a medias. Ante ORA-01089, volver a consultar el estado y continuar solo cuando se estabilice. Si no estabiliza, diagnosticar; no seguir por haber vencido un temporizador. Registrar cuándo se pierde el servicio para medir el intervalo completo.

## 4. Restaurar y recuperar

Desde Ubuntu, conectado RMAN a la raíz por autenticación del SO:

```bash
docker exec -i oralab-26ai rman target / <<'RMAN'
RESTORE DATAFILE 16;
RECOVER DATAFILE 16;
RMAN
```

**RESTORE** repone el archivo desde la copia; **RECOVER** aplica redo posterior. Revisar salida completa, errores RMAN/ORA y mensaje `media recovery complete`. No declarar éxito por una línea aislada ni continuar a ONLINE si falla la recuperación. Si se cambia la ruta física, se necesita un procedimiento específico de SET NEWNAME/SWITCH, no cubierto por el caso probado.

## 5. Volver al servicio

```bash
docker exec -i oralab-26ai sqlplus -s -L / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT FAILURE
ALTER SESSION SET CONTAINER=FREEPDB1;
ALTER DATABASE DATAFILE 16 ONLINE;
ALTER SESSION SET CONTAINER=CDB$ROOT;
SELECT name, open_mode FROM v$pdbs WHERE name='FREEPDB1';
EXIT
SQL
```

**Solo si FREEPDB1 está MOUNTED**, abrirla:

```bash
docker exec -i oralab-26ai sqlplus -s -L / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT FAILURE
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
EXIT
SQL
```

## 6. Validación técnica y de negocio

```bash
docker exec -i oralab-26ai sqlplus -s -L / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 180 PAGESIZE 100
SELECT name, open_mode FROM v$pdbs WHERE name='FREEPDB1';
SELECT file#, online_status, error FROM v$recover_file;
SELECT file#, status, error, recover FROM v$datafile_header WHERE file#=16;
ALTER SESSION SET CONTAINER=FREEPDB1;
SELECT COUNT(*) AS estudiantes FROM admin_academia.aca_estudiantes;
SELECT COUNT(*) AS matriculas FROM admin_academia.aca_matriculas;
SELECT estudiante_id, estado FROM admin_academia.aca_estudiantes
WHERE estudiante_id IN (101,102,104) ORDER BY estudiante_id;
EXIT
SQL
```

Esperado en el laboratorio: PDB READ WRITE, ningún pendiente de recuperación, 20.000 estudiantes y 60.000 matrículas. Para demostrar recuperación del cambio posterior al backup, **antes de la limpieza del simulacro** la fila 104 debe ser EGRESADO. El script 14d la devuelve después a ACTIVO; el runbook de un incidente real no debe modificar estados de negocio para normalizarlos artificialmente.

Ejecutar `bash scripts/ops/ro.sh scripts/lab5/15-healthcheck.sql` y, para el laboratorio, `bash scripts/lab5/16-verificacion-final.sh`. Verificar también respuesta de la aplicación. Documentar horas, alcance, copia usada, logs aplicados y consulta que prueba la integridad.

## Evidencia y lecciones

Ver [evidencia del simulacro D](../bitacora/lab5/evidencia/script/20261027T141829Z_14d-perdida-datafile.script.log) y [verificación final](../bitacora/lab5/evidencia/script/20261027T142003Z_16-verificacion-final.script.log).

La pieza etiquetada LAB5_SIMULACRO_D terminó correctamente; se restauró datafile 16, se completó media recovery y se reabrió FREEPDB1. A diferencia de la restauración completa de C (50 s y regreso al backup), D aplicó redo y conservó el cambio posterior. La FRA y los archivos comparten volumen en este laboratorio: eso no protege de la pérdida de todo el volumen; las copias reales deben conservarse en un dominio independiente.
