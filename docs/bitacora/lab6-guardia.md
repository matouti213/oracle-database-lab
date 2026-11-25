# Lab 6 — Guardia nocturna

## INC-601 · La ficha del alumno 101 se queda bloqueada

- Detección: 	Aviso de Ana García, de secretaría, al guardar la ficha del alumno 101.
- Impacto: Ana se quedó esperando al guardar esa ficha.
- Diagnóstico: 	La sesión 61 de Ana esperaba un bloqueo TX de la sesión 207, módulo matriculas, acción cierre-periodo. El bloqueador tenía 1 registro de undo.
- Causa raíz: La sesión de matrículas dejó abierta una transacción que retenía la fila que Ana necesitaba actualizar.
- Intervención: Si ejecutaste ALTER SYSTEM KILL SESSION '207,22478' IMMEDIATE;, anótalo. Si el bloqueo desapareció antes, escribe que no hizo falta intervenir.
- Validación: 0 sesiones de Ana bloqueadas. Alumno 101 en estado ACTIVO.
- Acción preventiva: Explica cómo evitarías que cierre-periodo se quede esperando con una transacción abierta.

## INC-602 · La aplicación recibe ORA-12514

- Detección: Aviso del equipo de matrículas al intentar conectar por academia_app.
- Impacto: Las nuevas conexiones de matrículas por academia_app fallaban.
- Diagnóstico: academia_app figuraba con ARRANCADO = NO. El listener seguía anunciando freepdb1 como READY.
- Causa raíz: El servicio academia_app estaba detenido. La base seguía atendiendo conexiones por freepdb1.
- Intervención: Ejecutaste 03-servicio.sql para arrancar academia_app con DBMS_SERVICE.START_SERVICE y guardar el estado con SAVE STATE.
- Validación: Listener READY y conexión nueva verificada: APP_ACADEMIA / FREEPDB1 / academia_app.
- Acción preventiva: Propón una prueba de conexión por academia_app después de cada reinicio o despliegue.

## INC-603 · La aplicación recibe ORA-28000

- Detección: Aviso del equipo de matrículas tras el despliegue. El ticket menciona el proceso trimestral de bajas.
- Impacto: La aplicación no podía iniciar sesión con APP_ACADEMIA.
- Diagnóstico: Anota el estado exacto de APP_ACADEMIA que aparece en tu log: LOCKED o LOCKED(TIMED). Esa diferencia justifica la causa.
- Causa raíz: Si tu log muestra LOCKED, el bloqueo fue explícito. La pista del ticket apunta a que el proceso de bajas incluyó una cuenta de aplicación.
- Intervención: Si ejecutaste el desbloqueo, la sentencia fue ALTER USER app_academia ACCOUNT UNLOCK; en FREEPDB1.
- Validación: Conexión nueva verificada con la cuenta recuperada: APP_ACADEMIA / FREEPDB1 / academia_app.
- Acción preventiva: Propón que el proceso de bajas distinga las cuentas personales de las cuentas de servicio antes de aplicar bloqueos.
