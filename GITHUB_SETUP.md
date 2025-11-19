# Instrucciones para crear GitHub Pages

## Paso 1: Crear el repositorio en GitHub

1. Ve a [GitHub](https://github.com) e inicia sesión
2. Haz clic en el botón **"+"** (arriba derecha) y selecciona **"New repository"**
3. Configura el repositorio:
   - **Repository name**: `hockey-tactical-lab` (o el nombre que prefieras)
   - **Description**: "Seminario Práctico: Del Modelo a la Tarea - Aplicación web interactiva"
   - **Visibility**: Selecciona **Public** (necesario para GitHub Pages gratuito)
   - ⚠️ **NO marques** "Initialize this repository with a README"
   - Haz clic en **"Create repository"**

## Paso 2: Conectar el repositorio local con GitHub

GitHub te mostrará instrucciones. Ejecuta estos comandos en tu terminal:

```bash
git remote add origin https://github.com/TU_USUARIO/hockey-tactical-lab.git
git push -u origin main
```

**Nota**: Reemplaza `TU_USUARIO` con tu nombre de usuario de GitHub.

Si te pide autenticación:
- Para HTTPS: Usa un **Personal Access Token** (crea uno en Settings > Developer settings > Personal access tokens)
- O configura SSH para conexiones más seguras

## Paso 3: Configurar GitHub Pages

1. Ve a tu repositorio en GitHub
2. Haz clic en **Settings** (Configuración)
3. En el menú lateral, busca **Pages**
4. En **Source**, selecciona **Deploy from a branch**
5. En **Branch**, selecciona **main** y **/ (root)**
6. Haz clic en **Save**
7. Espera unos minutos y tu sitio estará disponible en:
   ```
   https://TU_USUARIO.github.io/hockey-tactical-lab/
   ```

## Paso 4: Actualizar el README con el enlace

Una vez que tengas la URL de GitHub Pages, puedes actualizar el README.md con el enlace en vivo.

## Opcional: Cambiar la configuración de Git

Si quieres configurar tu nombre y email de Git correctamente:

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu-email@ejemplo.com"
```

## Solución de problemas

### Si el sitio no carga
- Verifica que el repositorio sea **Public**
- Espera 5-10 minutos después de activar Pages
- Verifica que el archivo `index.html` esté en la raíz del repositorio
- La URL será directamente `https://TU_USUARIO.github.io/hockey-tactical-lab/` (sin necesidad de agregar `/index.html`)

### Si necesitas cambiar el nombre del repositorio
1. Ve a Settings > General
2. Cambia el "Repository name"
3. La URL de GitHub Pages se actualizará automáticamente

