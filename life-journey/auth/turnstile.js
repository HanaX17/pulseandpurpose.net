/* Public site key only. Supabase verifies each token with its server-side secret. */
(() => {
  'use strict';
  const query = new URLSearchParams(location.search);
  const state = query.get('state') || '';
  const sitekey = query.get('sitekey') || '';
  const language = ['zh-cn', 'zh-tw', 'en'].includes(query.get('lang')) ? query.get('lang') : 'en';
  const chinese = language.startsWith('zh');
  document.documentElement.lang = language;
  const status = document.getElementById('status');
  const text = (en, zh) => { status.textContent = chinese ? zh : en; };
  let parentOrigin = null;
  try {
    const p = new URL(query.get('parentOrigin'));
    if (!p.username && !p.password && (p.protocol === 'https:' ||
      (p.protocol === 'http:' && ['localhost', '127.0.0.1', '[::1]'].includes(p.hostname)))) parentOrigin = p.origin;
  } catch { /* Native WebView has no parent origin. */ }
  const send = (result, token) => {
    const message = { type: 'life-journey-auth-challenge', state, status: result };
    if (token) message.token = token;
    if (window.ReactNativeWebView) window.ReactNativeWebView.postMessage(JSON.stringify(message));
    else if (parentOrigin && window.parent !== window) window.parent.postMessage(message, parentOrigin);
  };
  if (!/^[a-zA-Z0-9_-]{8,128}$/.test(sitekey) || !/^[a-zA-Z0-9-]{16,128}$/.test(state)) {
    text('Open this check from the app.', '请从 App 打开安全验证。');
    send('error');
    return;
  }
  text('Loading security check…', '正在加载安全验证…');
  const fail = () => { text('Could not complete the check. Try again in the app.', '验证未完成，请回到 App 重试。'); send('error'); };
  window.onStoryChallengeReady = () => {
    try {
      window.turnstile.render('#challenge', {
        sitekey, language, theme: 'auto', size: 'flexible',
        callback: (token) => { status.textContent = ''; send('token', token); },
        'expired-callback': () => { text('Please repeat the check in the app.', '请回到 App 重新验证。'); send('expired'); },
        'error-callback': () => { fail(); return true; },
        'timeout-callback': fail,
      });
      send('ready'); // Stop the app's loading timeout; let Turnstile handle interaction time.
    } catch { fail(); }
  };
  const script = document.createElement('script');
  script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onStoryChallengeReady&render=explicit';
  script.async = true;
  script.onerror = fail;
  document.head.appendChild(script);
})();
