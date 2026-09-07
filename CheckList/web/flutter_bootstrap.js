{{flutter_js}}
{{flutter_build_config}}

// Sirve CanvasKit desde la copia local del SDK en vez de gstatic.com —
// necesario en entornos donde esa descarga externa falla (p. ej.
// bloqueada por un antivirus).
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
