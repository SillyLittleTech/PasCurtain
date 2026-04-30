{{flutter_js}}
{{flutter_build_config}}

const userAgent = navigator.userAgent.toLowerCase();
const isSafari = userAgent.includes('safari') && !userAgent.includes('chrome') && !userAgent.includes('android');

const config = {};

// Temporary workaround for Safari 26.5 + Flutter 3.41.7 regression.
// For Safari, force the HTML renderer to avoid a blank white page.
if (isSafari) {
  config.renderer = 'html';
}

_flutter.loader.load({
  config,
});
