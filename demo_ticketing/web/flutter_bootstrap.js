{{flutter_js}}
{{flutter_build_config}}

// Fallback fonts are served from the app's own folder, never fonts.gstatic.com:
// the bundled IBM Plex Sans Arabic covers Arabic and Latin, and the demo keeps
// every request on this origin. The loading screen goes once the app runs.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: 'assets/fallback-fonts/',
  },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      fontFallbackBaseUrl: 'assets/fallback-fonts/',
    });
    await appRunner.runApp();
    const loading = document.getElementById('loading');
    if (loading) {
      loading.style.opacity = '0';
      setTimeout(function () { loading.remove(); }, 350);
    }
  },
});
