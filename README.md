# ProyectoFinal_AgendaParaCitas

Aplicación web para gestionar la agenda de citas de un consultorio: registrar citas, consultarlas y llevar el control de su estado.

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

## Cómo hacer un pull request

Pasos para un programador que va a agregar una funcionalidad. La rama correcta para integrar es `develop`; `main` solo recibe cambios desde `develop`.

```bash
# 1. Clonar el repositorio (solo la primera vez)
git clone https://github.com/MrChetoZzz/ProyectoFinal_AgendaParaCitas.git
cd ProyectoFinal_AgendaParaCitas

# 2. Actualizar develop y crear tu rama a partir de ella
git checkout develop
git pull origin develop
git checkout -b feature/nombre-de-la-funcionalidad

# 3. Trabaja en tu código, guarda los cambios y súbelos a tu rama
git add .
git commit -m "feat: descripción breve del cambio"
git push -u origin feature/nombre-de-la-funcionalidad
```

4. En GitHub, abre el pull request de `feature/nombre-de-la-funcionalidad` hacia `develop` y espera a que se revise y se fusione.
5. Cuando `develop` esté lista para liberarse, abre el pull request de `develop` hacia `main`.

Reglas: nunca subas cambios directamente a `main` ni a `develop`. Todo cambio entra por una rama `feature/*` y un pull request hacia `develop`.

## Seguridad

No se guardan credenciales ni cadenas de conexión en este repositorio. Las credenciales se suministran por variables de entorno.
