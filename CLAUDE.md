# Apps_Web

Repositorio **público**, separado a propósito de `Apps_GooglePlay` (privado) — aquí solo viven apps pensadas para publicarse como web (Flutter Web + PWA), servidas gratis con GitHub Pages. Cada app es una carpeta hermana, igual que `AppGastos` dentro de `Apps_GooglePlay`.

Al ser público, nunca debe tener nada sensible dentro (claves, datos reales de nadie...) — todas estas apps guardan sus datos 100% en el navegador de quien las usa (Hive → IndexedDB), nunca en este repo ni en ningún servidor.

## Apps

### CheckList

Listas personalizables (creas tú el nombre: "Videojuegos", "Tareas de casa"...) con elementos que se marcan como hechos. Pensada para uso personal en iPhone (Safari → "Añadir a pantalla de inicio"), sin cuenta ni servidor.

- **Stack**: Flutter Web, sin backend.
- **Almacenamiento**: Hive, local en el navegador (IndexedDB en web). Sin sincronización entre dispositivos — cada navegador tiene su propia copia.
- **Renderer**: CanvasKit servido desde la copia local del SDK (`web/flutter_bootstrap.js` fija `canvasKitBaseUrl: "canvaskit/"`) en vez de la CDN de Google — necesario porque en la máquina de desarrollo esa descarga externa estaba bloqueada (probablemente por el antivirus). Bundlear esto localmente también hace la PWA más resistente sin conexión.
- **Publicación**: GitHub Pages, sirviendo `flutter build web --base-href /Apps_Web/checklist/` (el subpath tiene que coincidir con dónde vive la carpeta publicada).
