const isBundledApp =
  window.location.protocol === 'file:' ||
  window.location.hostname === 'appassets.shiguang';

window.__SHIGUANG_CONFIG__ = {
  apiBaseUrl: 'http://127.0.0.1:8000',
  demoMode:
    isBundledApp ||
    new URLSearchParams(window.location.search).get('demo') === '1',
};
