// B23 sign-in: renders Google's button with this page's challenge nonce and posts the credential in the
// page's same-origin form (with its antiforgery token). No inline script, so the page keeps a strict CSP.
(function () {
  'use strict';
  var target = document.getElementById('gsi');
  var form = document.getElementById('signin-form');
  if (!target || !form) { return; }
  var tries = 0;
  function start() {
    if (!(window.google && google.accounts && google.accounts.id)) {
      if (++tries < 100) { setTimeout(start, 100); }
      return;
    }
    google.accounts.id.initialize({
      client_id: target.dataset.clientId,
      nonce: target.dataset.nonce,
      auto_select: false,
      cancel_on_tap_outside: true,
      callback: function (response) {
        form.elements.credential.value = response.credential;
        form.submit();
      }
    });
    google.accounts.id.renderButton(target, { theme: 'outline', size: 'large', text: 'signin_with', shape: 'pill' });
  }
  start();
})();
