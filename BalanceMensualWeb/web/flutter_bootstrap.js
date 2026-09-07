{{flutter_js}}
{{flutter_build_config}}

// Sirve CanvasKit desde la copia local del SDK en vez de gstatic.com —
// necesario en entornos donde esa descarga externa falla (p. ej.
// bloqueada por un antivirus), y hace la PWA más resistente sin conexión.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
