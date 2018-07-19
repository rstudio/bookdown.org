// do not show the subpath in the URL in the browser's address bar, because
// bookdown.org's real home is at bookdown.org/home/, which is an ugly URL
(function() {
  var loc = window.top.location, his = window.top.history;
  if (loc.protocol === 'https:' && loc.pathname !== '/' && his.replaceState)
    his.replaceState({}, '', '/');
})();
