
## Parte B: respaldo del Lab 3

- Copia: backups/20261026T174113Z_lab3-final.
- Tamaño mostrado: 767 MB.
- Tiempo total del respaldo y arranque: 1 min 50,269 s.
- Integridad: todas las comprobaciones SHA-256 dieron OK.
- Archivos fuera del volumen: 0, según manifiesto.txt.
- Aunque Oracle muestra los cinco datafiles de negocio bajo
  /opt/oracle/product/26ai/dbhomeFree/dbs/, readlink -f resuelve
  sus rutas a /opt/oracle/oradata/dbconfig/FREE/dbs/.
  Por tanto, están incluidos en la copia del volumen.
- La restauración aún no se ha ejecutado; su duración no se ha medido.
  El tiempo del respaldo no es el tiempo de recuperación.


## Parte E: arranque por etapas y alert log

- En NOMOUNT, la instancia aparece STARTED y permite consultar
  v$parameter. Consultar v$database produce ORA-01507.
- En MOUNT, Oracle conoce los 16 datafiles mediante los control files,
  pero consultar dba_tables produce ORA-01219.
- En OPEN, la base queda READ WRITE. FREEPDB1 también se abre
  automáticamente y dba_pdb_saved_states muestra su estado OPEN.
- Evidencias: archivos terminados en _06-arranque-por-etapas.script.log,
  _06-alert-log.script.log y _06-alert-contexto.script.log.
- Los errores ORA-27300 a ORA-27303 examinados están fechados
  el 2026-07-05. El caso chdir() aparece junto a ORA-07427:
  cannot change directory to dbs. Son anteriores al laboratorio;
  no aparecen nuevas coincidencias en los arranques del 2026-10-26
  dentro del registro examinado.
- El último arranque completa ALTER DATABASE OPEN y abre FREEPDB1
  en lectura y escritura.


## Parte G: memoria y cache

- Modelo ASMM: memory_size=0, memory_target=0 y sga_target=1536M.
  La PGA se gestiona aparte con pga_aggregate_target=512M.
- ACA_ESTUDIANTES tiene 20000 filas y 244 bloques según sus estadísticas.
- Ambas rondas devuelven 17600 estudiantes ACTIVO.
- Ronda fría: 355 lecturas lógicas y 261 físicas.
- Ronda caliente: 247 lecturas lógicas y 0 físicas.
- Tasa de acierto de la segunda ronda: 1 - 0/247 = 100 %.
- Las estadísticas medidas son de la sesión, no exclusivamente de la
  tabla. El exceso de lecturas de la primera ronda puede incluir
  trabajo interno de preparación y consultas al diccionario.
- Tras las consultas hay 245 buffers de la tabla en v$bh,
  coherente con los 244 bloques y la cabecera del segmento.
- Evidencias: _08-memoria.spool.log y _08-experimento-cache.script.log.

