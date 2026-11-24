# ProyectoFinal_AgendaParaCitas

Aplicación web para gestionar la agenda de citas de un consultorio (médico o dental): registrar citas, consultarlas y llevar el control de su estado.

## Problema y solución

En un consultorio, las citas se agendan por teléfono o en papel y es fácil que se pierdan, se dupliquen o se olviden. Esta aplicación centraliza la agenda: la recepcionista registra una cita con paciente, fecha, hora y motivo, y consulta la lista de citas del día en un solo lugar. La aplicación está formada por una SPA en React que consume una API en ASP.NET Core, con los datos persistidos en PostgreSQL.

## Stack tecnológico

| Elemento | Tecnología |
| --- | --- |
| Frontend | SPA con React 19 y TypeScript (Vite) |
| Backend | ASP.NET Core Web API con .NET 10 |
| Base de datos | PostgreSQL |

> Nota: el backend usa inicialmente una lista en memoria para las citas. El siguiente paso es persistir con PostgreSQL mediante EF Core, con la cadena de conexión suministrada únicamente por variable de entorno (ver "Variables de entorno"). Nunca se guardan credenciales en el repositorio.

## Estructura del proyecto

```text
.
├── .github/workflows/ci.yml   # Pipeline de GitHub Actions
├── docs/
│   ├── c4-contexto.md         # Diagrama C4 de contexto
│   └── c4-contenedores.md     # Diagrama C4 de contenedores
├── frontend/                  # SPA React 19 + TypeScript (Vite)
│   └── src/
├── backend/
│   └── AgendaCitas.Api/       # API ASP.NET Core .NET 10
│       └── Models/
├── .env.example               # (en frontend/) ejemplo de variables del frontend
├── .gitignore
└── README.md
```

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

## Ejecución local

### Requisitos previos

- Node.js 20 o superior y npm.
- SDK de .NET 10.
- (Opcional, para persistencia futura) PostgreSQL.

### Frontend

```bash
cd frontend
npm install
npm run dev
```

La aplicación queda disponible en http://localhost:5173 y consume la API en http://localhost:5000.

### Backend

```bash
cd backend/AgendaCitas.Api
dotnet run
```

La API queda disponible en http://localhost:5000 y su estado en http://localhost:5000/api/health.

## Variables de entorno

| Variable | Uso |
| --- | --- |
| `VITE_API_URL` | URL base de la API que consume el frontend (por defecto, `http://localhost:5000`). Ver `frontend/.env.example`. |
| `ConnectionStrings__AgendaDb` | Cadena de conexión a PostgreSQL para la API. Se suministra únicamente por variable de entorno; no tiene ningún valor en el repositorio. |

## Enlaces publicados

- Frontend publicado: **Pendiente de publicar**
- API publicada: **Pendiente de publicar**

## Seguridad

No se guardan credenciales ni cadenas de conexión en este repositorio. Las credenciales se suministran por variables de entorno y los archivos de secretos (`.env`, `appsettings.*.json` con secretos) están excluidos en `.gitignore`.
