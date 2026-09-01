# Archivos: sin pruebas todavía

Este módulo es el único sin una sola prueba. No es que no haga falta: es lo que
queda por hacer, y esta carpeta está aquí para que se vea en el árbol y no solo
en un informe de cobertura.

Lo que hay que cubrir, con `test/features/chat/` al lado como plantilla —los dos
módulos tienen la misma forma:

- `files_controller_test.dart`
  - `load` llena la lista; si falla, se enseña el mensaje del servidor (el caso
    normal en clase es un proyecto sin bucket conectado)
  - `busyFileId` marca solo la fila afectada y se limpia en `finally`, tanto si
    sale bien como si falla
  - `upload` vuelve a leer la lista en vez de añadir a mano lo subido
  - `remove` quita la fila
- `files_source_test.dart`: que pegue a `db.files.*` y traduzca lo que llega a
  `StoredFile`
- `files_dependencies_test.dart`: que el contenedor sepa construir la cadena, y
  que se pueda volver a entrar a la pantalla después de salir (el motivo por el
  que los tres registros llevan `fenix`)

Cuando esté, se borra este archivo.
