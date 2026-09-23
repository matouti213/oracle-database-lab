\# Guía de colaboración



\## Nombres de ramas



Cada tarea se desarrolla en una rama creada desde main.



Formato:

<tipo>/<numero-issue>-<descripcion-corta>



Ejemplos:

\- docs/1-contribution-guidelines

\- feat/3-add-customer-table

\- fix/5-correct-query



Utilizamos nombres breves, sin espacios y con guiones entre palabras.



\## Mensajes de commit



Utilizamos Conventional Commits.



Formato:

<tipo>(<ambito-opcional>): <descripcion>



Tipos habituales:

\- feat: nueva funcionalidad.

\- fix: corrección de errores.

\- docs: cambios en documentación.

\- test: incorporación o modificación de pruebas.

\- refactor: reorganización del código sin cambiar su comportamiento.

\- chore: tareas de mantenimiento.



Ejemplo:

docs: add contribution guidelines (Refs #1)



Usamos Refs #N para relacionar los commits con el Issue correspondiente.



\## Pull Requests



Todo cambio debe pasar por un Pull Request y recibir al menos

una aprobación de otro integrante antes de fusionarse en main.



El PR debe explicar:

\- Qué se ha cambiado y por qué.

\- Cómo se ha comprobado el cambio.

\- Qué Issue resuelve, utilizando Closes #N.



El autor responde a la revisión y realiza las correcciones

en la misma rama y en el mismo Pull Request.

