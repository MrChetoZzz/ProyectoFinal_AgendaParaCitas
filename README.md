# ProyectoFinal_AgendaParaCitas

Aplicación web para gestionar la agenda de citas de un consultorio (médico o dental): registrar citas, consultarlas y llevar el control de su estado.

## Problema y solución

En un consultorio, las citas se agendan por teléfono o en papel y es fácil que se pierdan, se dupliquen o se olviden. Esta aplicación centraliza la agenda: la recepcionista registra una cita con paciente, fecha, hora y motivo, y consulta la lista de citas del día en un solo lugar.

## Flujo de ramas e integración

- `main`: versión estable. Solo recibe cambios mediante pull request desde `develop`.
- `develop`: rama de integración. Recibe los cambios de las ramas `feature/*`.
- `feature/*`: ramas de desarrollo de funcionalidades, por ejemplo `feature/registro-citas`.

Flujo de integración:

1. Crea una rama `feature/<nombre>` a partir de `develop`.
2. Desarrolla y sube tus cambios a esa rama.
3. Abre un pull request de `feature/<nombre>` a `develop`.
4. Cuando `develop` está lista para liberarse, abre un pull request de `develop` a `main`.
5. El pipeline de GitHub Actions valida la compilación del frontend y del backend en cada push y pull request a `develop` y a `main`.

## Seguridad

No se guardan credenciales ni cadenas de conexión en este repositorio. Las credenciales se suministran por variables de entorno y los archivos de secretos (`.env`, `appsettings.*.json` con secretos) están excluidos en `.gitignore`.
