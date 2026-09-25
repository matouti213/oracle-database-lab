\# Laboratorio 2 — Preguntas de comprobación



Integrantes: Amine y Oussama.



\## 1. ¿Por qué un Issue sin criterios de aceptación es un problema, aunque la descripción general parezca clara?



Porque no establece cómo comprobar que el trabajo está terminado.

El autor y el revisor pueden interpretar de forma diferente una

descripción general. Los criterios de aceptación convierten la

tarea en condiciones verificables. En nuestra práctica, comprobar

que existe CONTRIBUTING.md y que está enlazado desde README.md

permite evaluar el resultado de manera concreta.



\## 2. Explica la diferencia entre "Refs #N" y "Closes #N" en un mensaje de commit o en la descripción de un Pull Request.



Refs #N relaciona el trabajo con un Issue, pero no lo cierra

automáticamente. Closes #N expresa que el cambio resuelve ese Issue

y permite cerrarlo automáticamente cuando se integra en la rama

predeterminada, que en nuestro repositorio es main.



Usamos Refs #1 durante el trabajo y Closes #1 en la descripción

del PR que proponía resolverlo.



\## 3. ¿Qué ocurre exactamente si intentas hacer git push directamente sobre una branch main protegida? ¿Es un error tuyo o un fallo del sistema?



Si las reglas exigen pasar por un PR y se aplican al usuario,

GitHub rechaza el push. El commit permanece en el repositorio

local, pero no actualiza main en el remoto.



En nuestra prueba apareció GH006: Protected branch update failed

y el mensaje Changes must be made through a pull request.

No fue un fallo del sistema: la protección estaba funcionando.

Fuera de una prueba deliberada, intentar saltarse ese flujo sería

un error de procedimiento.



\## 4. Un compañero te dice: "he aprobado el PR sin mirar los archivos, total ya me fío". ¿Qué riesgo tiene esa forma de revisar?



La confianza en una persona no permite comprobar un cambio concreto.

Podrían integrarse errores, información sensible, cambios ajenos

a la tarea o requisitos incompletos. La aprobación dejaría de ser

una evidencia de revisión. Es necesario leer el diff y comprobar

los criterios de aceptación y las pruebas correspondientes.



\## 5. Si el reviewer pide un cambio y tú ya habías hecho push de tu branch, ¿tienes que abrir un Pull Request nuevo? Explica qué ocurre técnicamente con el PR existente cuando haces un nuevo commit.



No hace falta abrir otro PR. Se corrige en la misma rama, se crea

un nuevo commit y se hace push. El PR sigue esa rama de origen,

por lo que incorpora los nuevos commits y actualiza el diff

respecto a la rama de destino.



En nuestra práctica corregimos los formatos Markdown de la guía

sin crear otro PR. Si existía una aprobación y está activada su

invalidación por nuevos commits, será necesaria otra aprobación.



\## 6. Describe con tus palabras la diferencia entre Merge commit, Squash and merge y Rebase and merge. ¿Cuál usarías para una branch con commits "wip", "fix", "fix2", "ok ya"?



Merge commit conserva los commits de la rama y añade un commit

de fusión que une ambas historias.



Squash and merge reúne los cambios de la rama en un único commit

nuevo sobre la rama de destino.



Rebase and merge reaplica los commits sobre la rama de destino,

con nuevos identificadores y sin crear un commit de fusión.



Para una rama con commits como "wip", "fix", "fix2" y "ok ya",

elegiríamos Squash and merge y escribiríamos un mensaje final

descriptivo, porque esos mensajes intermedios aportan poco al

historial de main.



\## 7. ¿Por qué borrar una branch después del merge no elimina el trabajo realizado en ella?



Una rama es una referencia a un commit. Borrarla elimina esa

referencia, pero los cambios integrados permanecen en main.



Con squash, main conserva el resultado en un commit nuevo,

aunque no conserva necesariamente los commits originales como

parte de su historial. Por eso Git puede advertir que la rama

no está completamente fusionada aunque su contenido ya esté

integrado. Antes de forzar el borrado comprobamos el merge y

que no hubiera diferencias ni trabajo pendiente.



\## 8. ¿Qué información debería contener siempre la descripción de un Pull Request, como mínimo?



Debe explicar qué necesidad resuelve, por qué se realiza el cambio,

qué se ha modificado y cómo se ha comprobado. También debe enlazar

el Issue relacionado.



Una estructura útil es Summary, Changes, Testing y Related Issue.

Cuando el PR resuelve completamente el Issue, podemos incluir

Closes #N. Las comprobaciones indicadas deben haberse realizado

realmente.



\## 9. Un reviewer escribe solo "esto está mal" como comentario. ¿Qué le falta a ese comentario para ser útil? Reescríbelo tú con un ejemplo inventado.



Le falta identificar el problema, explicar su consecuencia y

proponer una acción concreta. También debe indicar si bloquea

la aprobación.



Ejemplo:

"issue (blocking): El enlace del README apunta a CONTRIBUTING.txt,

pero el archivo del repositorio se llama CONTRIBUTING.md.

Corrige el destino del enlace y comprueba que abre la guía."



\## 10. ¿Qué diferencia hay entre que main esté protegida y que simplemente el equipo "se ponga de acuerdo" en no hacer push directo?



El acuerdo depende de que cada persona lo recuerde y lo cumpla.

La protección convierte esa norma en una restricción técnica:

GitHub bloquea las operaciones que incumplen las reglas.



Para que también afecte al administrador hay que configurar

la protección de forma que no pueda saltarse esas reglas.



\## 11. Explica con un ejemplo propio la diferencia entre un comentario issue: (blocking) y uno nitpick: (if-minor) en formato Conventional Comments.



Un comentario issue (blocking) señala un problema que debe

solucionarse antes de aprobar el cambio.



Ejemplo:

"issue (blocking): La guía permite integrar cambios sin revisión,

pero el requisito exige una aprobación. Corrige esa instrucción."



Un comentario nitpick (if-minor) propone un detalle menor que

no debería bloquear la integración.



Ejemplo:

"nitpick (if-minor): Podríamos usar el mismo estilo de mayúsculas

en todos los títulos para mantener una presentación uniforme."



\## 12. Si tu próximo commit es feat!: cambia la firma de la función principal de la API, ¿qué tipo de versión SemVer se dispara y por qué?



El signo ! declara un cambio incompatible. Para una API estable

versionada con SemVer, corresponde un incremento MAJOR, por

ejemplo de 1.4.2 a 2.0.0, porque los clientes pueden necesitar

adaptar su código a la nueva firma.



El mensaje por sí solo no publica una versión: una herramienta

de automatización o el proceso del equipo debe aplicar esa

regla de versionado.



\## 13. ¿Por qué abrir un Draft PR desde el primer commit estructural puede ahorrar tiempo al equipo, aunque parezca más lento para el autor individual?



Permite revisar pronto el enfoque y detectar problemas de diseño

o de interpretación antes de desarrollar todos los detalles.

Así se reduce el trabajo que habría que rehacer si el enfoque

fuera incorrecto.



El estado Draft comunica que el cambio todavía está en desarrollo

y no está listo para fusionarse, pero permite recibir comentarios.

