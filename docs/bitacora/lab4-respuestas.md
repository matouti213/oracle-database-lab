
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


## Parte H: procesos de Oracle y Linux

- LGWR tiene SPID 1379 en v$process y aparece como PID 1379,
  db_lgwr_FREE, al consultar /proc dentro del contenedor.
- docker top muestra los PID desde el anfitrión; pueden diferir
  de los SPID que Oracle ve dentro del contenedor.
- Se observaron cuatro archivadores ARCn y la base está en ARCHIVELOG.
- La sesión SQLcl de C##OPS_RO tenía un proceso servidor con SPID 2658.
  Al terminar esa conexión, la comprobación posterior no encontró
  servidores dedicados.
- Los recuentos se tomaron en momentos distintos y pueden variar.
  Además, varios registros de procesos Oracle pueden compartir SPID.
- No se deben sumar los RSS para calcular la memoria de la instancia:
  se contabilizarían repetidamente páginas de memoria compartida.
- Evidencias: _09-procesos.spool.log y _09-procesos-so.script.log.


## Preguntas de comprobación

### 1. ¿Por qué la copia es consistente? ¿Qué pasaría con la base abierta?
La copia se hizo después de SHUTDOWN IMMEDIATE: Oracle deshace las
transacciones sin confirmar, escribe los cambios pendientes y cierra
limpiamente la base. Después se detuvo el contenedor para copiar.
Copiar los archivos directamente con la base abierta no garantiza
que representen un mismo estado; sería necesario un procedimiento
de respaldo en caliente y la recuperación correspondiente.
Evidencia: 20261026T174113Z_00-backup-lab3.script.log,
parada limpia antes de la copia.

### 2. ¿Para qué sirven manifiesto.txt y SHA256SUMS?
El manifiesto identifica la copia: fecha, etiqueta, imagen, contenedor,
volumen, commit y número de archivos externos. SHA256SUMS permite
detectar modificaciones o corrupción de los archivos de la copia.
restaurar-estado.sh comprueba esas sumas antes de modificar el entorno.
Evidencia: 20261026T174518Z_00-verificacion-backup.script.log:
todas las sumas dieron OK y archivos_fuera_del_volumen=0.

### 3. Define RPO y RTO con los datos de tu copia.
RPO es el objetivo de pérdida máxima de datos tolerable, expresado
como tiempo. Esta copia permite regresar al estado del cierre limpio
del 26/10/2026; los cambios posteriores se perderían si restaurásemos
solo esa copia. No se ha establecido un objetivo numérico de RPO.
RTO es el tiempo objetivo para recuperar el servicio. Todavía no
hemos medido una restauración ni fijado un objetivo numérico.
El respaldo y posterior arranque tardaron 1 min 50,269 s, pero eso
no es una medición del tiempo de restauración.
Evidencia: 20261026T174113Z_00-backup-lab3.script.log.

### 4. ¿Dónde se crearon los datafiles de V000 y por qué?
V000 utilizó nombres relativos, como academia01.dbf, y no había
DB_CREATE_FILE_DEST configurado. Oracle registró las rutas bajo
/opt/oracle/product/26ai/dbhomeFree/dbs/.
En mi imagen, dbs es un enlace a /opt/oracle/oradata/dbconfig/FREE/dbs:
los cinco archivos estaban dentro del volumen, aunque en una carpeta
no estándar. Por eso el respaldo encontró cero archivos externos.
Configurar DB_CREATE_FILE_DEST y utilizar creación con OMF habría
permitido que Oracle eligiera el destino y nombre administrados.
También se evita la ambigüedad usando rutas absolutas explícitas.
Evidencia: 20261026T200211Z_01-diagnostico.script.log:
db_create_file_dest vacío y rutas reales DENTRO del volumen.

### 5. ¿Por qué RENAME DATAFILE no basta para mover un archivo?
Porque actualiza la referencia que Oracle guarda del archivo,
pero no realiza su copia física. Usamos OFFLINE NORMAL, cp -p,
RENAME DATAFILE y ONLINE. Solo después del éxito se eliminó el original.
Evidencia: 20261026T200303Z_03-reubicar-datafiles.script.log:
los cinco datafiles quedaron en FREE/FREEPDB1, disponibles y con
MAXSIZE de 1024 MB.

### 6. ¿Por qué crear V003 y no editar V000? ¿Por qué invalidar la contraseña?
V000 ya se aplicó y debe conservarse como registro del cambio original.
V003 incorpora una corrección nueva y trazable. Borrar una contraseña
del archivo no la elimina del historial ni invalida copias anteriores.
NO AUTHENTICATION revoca el acceso con contraseña y conserva los
objetos de los propietarios como cuentas de solo esquema.
Evidencia: 20261026T200418Z_04-V003__cuentas_esquema_sin_password.spool.log:
los cinco usuarios ADMIN_* muestran AUTHENTICATION_TYPE=NONE.

### 7. ¿Qué demuestra la prueba de persistencia y por qué va después de reubicar?
Demuestra que los tablespaces y tablas comprobados sobreviven al
borrado y recreación del contenedor usando el mismo volumen.
Se conservaron los cinco tablespaces ONLINE y las 14 tablas.
ACA_ESTUDIANTES tenía cero filas antes y después: V002 se aplicó luego.
Se hace después de reubicar para evitar perder archivos que pudieran
estar en la capa del contenedor. En mi imagen ya estaban en el volumen,
pero se trasladaron igualmente a su carpeta estándar.
Evidencia: 20261026T201701Z_03-prueba-persistencia.script.log:
resultados iguales antes y después y solo puerto 1521 publicado.


### 8. Tres datos de la instancia y tres de la base de datos.
De la instancia: nombre FREE, host 91dd6fc398d8 y arranque
2026-10-26 20:17:05 en el momento de la consulta.
De la base: DBID 1509902213, fecha de creación 2026-07-05
y modo ARCHIVELOG.
La instancia comprende memoria y procesos; la base persiste en archivos.
Evidencia: 20261026T202542Z_05-instancia-y-base.spool.log.

### 9. ¿Qué lee Oracle en NOMOUNT, MOUNT y OPEN?
En NOMOUNT lee el SPFILE o PFILE, reserva memoria y arranca procesos.
v$parameter responde, pero v$database produce ORA-01507 porque
todavía no se han abierto los control files.
En MOUNT abre los control files y conoce la estructura de la base:
en mi caso, 16 datafiles. El diccionario todavía no está disponible;
consultar dba_tables produce ORA-01219.
En OPEN abre los datafiles y redo logs y permite el uso normal.
Evidencia: 20261026T202914Z_06-arranque-por-etapas.script.log.

### 10. ¿Por qué FREEPDB1 se abre sola? ¿Qué hacer si no ocurre?
Porque tiene guardado su estado de apertura. Mi consulta a
dba_pdb_saved_states muestra FREEPDB1, instancia FREE, estado OPEN.
Si quedara MOUNTED, ejecutaría desde CDB$ROOT:
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;
Evidencia: 20261026T202914Z_06-arranque-por-etapas.script.log:
FREEPDB1 queda READ WRITE.

### 11. Clasifica ORA-00800 y ORA-20013 del alert log.
En mi evidencia aparece ORA-00800 con Set Priority Failed para VKTM
y LGWR. En el contexto de este contenedor es el aviso conocido
descrito en el laboratorio: Oracle no consigue elevar su prioridad.
El arranque termina correctamente y FREEPDB1 abre en lectura y escritura.
No clasificaría cualquier ORA-00800 como inocuo sin mirar sus argumentos.
ORA-20013 asociado a DBMS_QOPATCH se describe en el enunciado como
un problema conocido de acceso al inventario de parches de la imagen.
No aparece en el extracto que obtuve, por lo que no afirmo haberlo observado.
Evidencia: 20261026T203014Z_06-alert-log.script.log.
Los ORA-27300 examinados aparte eran históricos, del 2026-07-05:
20261026T203036Z_06-alert-contexto.script.log.

### 12. Diferencia entre v$parameter y v$spparameter con db_files.
v$parameter muestra el valor efectivo de la sesión; v$spparameter,
la configuración del SPFILE que se utilizará al arrancar.
Al fijar db_files=300 con SCOPE=SPFILE, el valor efectivo siguió
en 200 y el SPFILE mostró 300: el cambio estaba pendiente de reinicio.
Después del RESET, db_files siguió en 200 y su entrada del SPFILE
quedó con ISSPECIFIED=FALSE.
Evidencia: 20261026T203623Z_07-parametros-cambios-completo.script.log.

### 13. ¿Qué hace SCOPE=BOTH y cuál es el alcance por defecto?
SCOPE=BOTH cambia el valor en memoria y lo guarda en el SPFILE.
En el experimento, open_cursors pasó a 500 en ambos sitios.
Después lo devolvimos a 300.
Si la instancia arrancó con SPFILE, BOTH es el alcance por defecto
de ALTER SYSTEM SET cuando se omite SCOPE.
Evidencia: 20261026T203623Z_07-parametros-cambios-completo.script.log.

### 14. ¿Por qué PROCESSES rechaza el cambio en memoria?
PROCESSES determina estructuras y límites que se establecen al
arrancar la instancia, por lo que su cambio requiere reinicio.
Aunque esta versión muestra ISSYS_MODIFIABLE=IMMEDIATE, el intento
de cambiarlo a 250 con SCOPE=MEMORY produjo ORA-02097 y ORA-02095.
Para cambiarlo se usaría SCOPE=SPFILE y un reinicio planificado.
En el laboratorio quedó en su valor original: 200.
Evidencias: 20261026T203430Z_07-parametros-lectura.spool.log
y 20261026T203623Z_07-parametros-cambios-completo.script.log.

### 15. ¿Para qué sirve versionar el PFILE? ¿Qué es configuration drift?
El PFILE es una representación textual de la configuración.
Guardarlo en Git permite comparar versiones, revisar cambios
y disponer de una referencia para recuperación.
Configuration drift es la divergencia de la configuración real
respecto a una configuración de referencia, por ejemplo por cambios
manuales que no se documentaron.
Mi exportación desde SPFILE tiene 32 líneas y la de memoria 122;
esta última incluye también parámetros efectivos derivados o por defecto.
Evidencia: 20261026T203723Z_07-pfile.script.log y los dos archivos
initFREE_lab4*.ora de la carpeta evidencia/config/.


### 16. ¿Qué modelo de gestión de memoria usa la instancia?
Usa ASMM: memory_size=0, memory_target=0 y sga_target=1536M.
Oracle distribuye automáticamente la memoria entre los componentes
de la SGA. La PGA se gestiona aparte con pga_aggregate_target=512M
y pga_aggregate_limit=2G.
db_cache_size=0 no significa que no exista caché, sino que no hemos
fijado un mínimo para ese componente.
Evidencia: 20261026T203914Z_08-memoria.spool.log.

### 17. Interpreta el experimento de caché.
Ambas consultas encontraron 17600 estudiantes ACTIVO.
La primera ronda tuvo 355 lecturas lógicas y 261 físicas.
La segunda tuvo 247 lecturas lógicas y ninguna física:
los bloques necesarios ya estaban en memoria.
Las lecturas lógicas son accesos a bloques mediante la caché;
no equivalen exclusivamente a aciertos, porque un bloque puede
tener que traerse primero mediante una lectura física.
Las medidas son de la sesión: la primera ejecución puede incluir
trabajo adicional de preparación y consultas internas.
La tasa de acierto de la segunda ronda fue 1 - 0/247 = 100 %.
Después se observaron 245 buffers de la tabla en v$bh.
Evidencia: 20261026T204153Z_08-experimento-cache.script.log.

### 18. ¿Por qué no se suma el RSS de los procesos?
Porque el RSS de varios procesos incluye páginas compartidas,
como las de la SGA. Sumarlos contabilizaría esas páginas varias veces.
Para analizar la memoria uso las vistas de SGA y PGA; docker stats
aporta además una medida del consumo del contenedor.
Evidencias: 20261026T203914Z_08-memoria.spool.log
y 20261026T204423Z_09-procesos-so.script.log.

### 19. Relaciona el SPID de LGWR con Linux.
En Oracle, LGWR tenía SPID 1379.
Al consultar /proc dentro del contenedor, el PID 1379 correspondía
a db_lgwr_FREE: es el mismo proceso.
docker top utiliza los PID del anfitrión Docker, mientras que Oracle
ve los PID del espacio de nombres del contenedor; por eso pueden
mostrar números distintos para el mismo proceso.
Evidencias: 20261026T204346Z_09-procesos.spool.log
y 20261026T204423Z_09-procesos-so.script.log.

### 20. ¿Qué hacen PMON y SMON? Pon un ejemplo.
PMON detecta procesos terminados anormalmente y coordina su limpieza.
En versiones modernas, CLMN y sus procesos auxiliares realizan
parte de esa limpieza y liberación de recursos.
Ejemplo: una conexión de cliente desaparece durante una transacción
y se deben recuperar los recursos y resolver la transacción pendiente.
SMON se ocupa de tareas de recuperación y mantenimiento de la instancia.
Ejemplo: después de una caída, interviene en la recuperación de instancia
para devolver la base a un estado consistente.
En mi consulta aparecieron PMON con SPID 1330, CLMN con 1334
y SMON con 1385.
Evidencia: 20261026T204346Z_09-procesos.spool.log.

### 21. ¿Por qué C##OPS_RO en vez de SYSTEM?
Se aplica el principio de mínimo privilegio: para observar no necesito
los amplios permisos administrativos de SYSTEM.
C##OPS_RO tiene CREATE SESSION, SET CONTAINER y SELECT_CATALOG_ROLE,
con visibilidad de los contenedores configurada mediante CONTAINER_DATA.
Puede consultar el catálogo y las vistas necesarias para monitorizar.
Los permisos concedidos no le permiten modificar tablas de negocio,
crear usuarios, cambiar parámetros con ALTER SYSTEM ni arrancar
o apagar la instancia como SYSDBA.
Evidencias: scripts/lab4/02-cuenta-observabilidad.sql
y 20261026T202542Z_05-instancia-y-base.spool.log,
donde la sesión utiliza C##OPS_RO.

### 22. ¿Qué dos vías de exposición de contraseñas se corrigen?
Primera: las contraseñas literales de los propietarios ADMIN_* en V000
y en el historial de Git. V003 las invalida con NO AUTHENTICATION,
sin alterar la migración histórica.
Segunda: la contraseña de SYS en los argumentos del ejecutor de
migraciones. La versión nueva usa autenticación del sistema operativo
dentro del contenedor mediante sqlplus / as sysdba.
Además, el creador del contenedor no pasa ORACLE_PWD cuando reutiliza
un volumen que ya contiene la base.
Evidencias: 20261026T200418Z_04-V003__cuentas_esquema_sin_password.spool.log,
scripts/deployment/env/08-aplicar-migraciones.sh
y scripts/deployment/env/05-crear-contenedor.sh.


## Preguntas tipo examen P1-P12

### P1. Respuestas A y D
SHUTDOWN IMMEDIATE deja la base cerrada consistentemente.
Al restaurar correctamente esa copia completa, puede abrirse
sin aplicar redo para recuperar una copia inconsistente.

### P2. Respuesta B
La secuencia es OFFLINE, copia física, RENAME DATAFILE y ONLINE.
RENAME DATAFILE actualiza la referencia de Oracle; no copia el archivo.

### P3. Respuestas A y C
STARTUP_TIME corresponde al arranque de la instancia y cambia
en cada arranque. CREATED corresponde a la creación de la base.
Recrear el contenedor conservando la base no cambia su DBID.

### P4. Respuestas A y C
En NOMOUNT ya están cargados los parámetros, por lo que se puede
consultar v$parameter. También es el estado adecuado para ejecutar
CREATE CONTROLFILE; el diccionario de la base aún no está abierto.

### P5. Respuesta B
Para cambiar a ARCHIVELOG, la base debe estar montada,
pero no abierta: estado MOUNT.

### P6. Respuesta B
Si se arrancó con SPFILE, el alcance por defecto es BOTH.
open_cursors cambia en memoria y queda persistido en el SPFILE.

### P7. Respuesta C
PROCESSES es un parámetro de instancia que no puede modificarse
desde una PDB. El intento produce ORA-65040.

### P8. Respuestas A y C
STARTUP PFILE permite arrancar con una configuración válida.
CREATE SPFILE FROM PFILE permite reconstruir el SPFILE
a partir de esa configuración corregida.

### P9. Respuesta B
ASMM gestiona la SGA. Un DB_CACHE_SIZE explícito de 512M
establece un mínimo para ese componente, no un tamaño fijo.

### P10. Respuestas A y D
Las áreas de trabajo, como la de ordenación, pertenecen a la PGA.
En servidor dedicado, la memoria de sesión también reside en la PGA.
Shared pool, log buffer y buffer cache pertenecen a la SGA.

### P11. Respuesta C
En un COMMIT síncrono normal, LGWR debe completar la escritura
del redo correspondiente antes de confirmar el éxito al cliente.
DBWn puede escribir los bloques de datos posteriormente.

### P12. Respuestas B y D
PMON y SMON son procesos fundamentales de la instancia.
ARC0 depende del archivado y CJQ0 de la ejecución de trabajos.

