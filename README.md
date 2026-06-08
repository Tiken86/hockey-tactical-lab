# Hockey Tactical Lab

Seminario Práctico: Del Modelo a la Tarea

Aplicación web para diseñar y analizar tareas de entrenamiento de hockey en **grupos y en tiempo real**. Los alumnos trabajan por grupos (acceso con un código) y el profesor recibe y revisa las entregas desde un panel propio.

## Cómo funciona

### Alumnos — `index.html`
1. Abren la app (URL de GitHub Pages).
2. **Crear grupo**: introducen el nombre del grupo + el **código de clase** que da el profesor. Reciben un **código de grupo** de 8 caracteres.
3. **Abrir grupo**: el resto del grupo entra con ese código de grupo, desde cualquier dispositivo.
4. Trabajan **a la vez en tiempo real**: análisis táctico y diseño de las 4 tareas. Todo se guarda solo en la nube.
5. **Entregar trabajo final**: al pulsar "Entregar", el proyecto pasa a solo-lectura y queda disponible para el profesor.

Requiere conexión a internet (si se cae, la app se bloquea y reconecta sola).

### Profesor — `profesor.html`
- Página separada protegida por **clave de profesor**.
- Lista todos los grupos: nombre, código, estado (borrador/entregado) y última edición.
- Permite ver cada entrega (análisis + tareas), imprimir y descargar el JSON.

## Características

- ✅ Colaboración en tiempo real por grupo (Supabase Realtime)
- ✅ Acceso por código de grupo, sin registro
- ✅ Guardado automático en la nube
- ✅ Diseño de 4 tipos de tarea (Dirigida, Estructurada, Especial, Competitiva)
- ✅ Informe técnico imprimible (PDF) y exportación JSON
- ✅ Panel del profesor con todas las entregas
- ✅ Responsive (móvil, tablet, ordenador)

## Tecnologías

- React 18 + Babel Standalone + Tailwind (vía CDN, sin build)
- Supabase (Postgres + RPC `SECURITY DEFINER` + Realtime Broadcast)

## Backend (Supabase)

El esquema está versionado en [`supabase/schema.sql`](supabase/schema.sql): tablas privadas (RLS deny-all) y todo el acceso vía funciones RPC. Los secretos (clave de profesor y código de clase) **no** están en el repositorio; se guardan cifrados (bcrypt) en la tabla de configuración.

## GitHub Pages

- App de alumnos: `https://TU_USUARIO.github.io/hockey-tactical-lab/`
- Panel del profesor: `https://TU_USUARIO.github.io/hockey-tactical-lab/profesor.html`

## Licencia

Uso educativo.
