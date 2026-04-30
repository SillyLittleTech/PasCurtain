{{flutter_js}}
{{flutter_build_config}}

const userAgent = navigator.userAgent.toLowerCase();
const isSafari = userAgent.includes('safari') && !userAgent.includes('chrome') && !userAgent.includes('android');

const config = {};

// Temporary workaround for Safari 26.5 + Flutter 3.41.7 regression.
// Force CanvasKit on Safari to avoid Flutter choosing an incompatible build.
if (isSafari) {
  config.renderer = 'canvaskit';
}

_flutter.loader.load({
  config,
});
