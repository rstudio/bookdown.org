// do not show the subpath in the URL in the browser's address bar, because
// bookdown.org's real home is at bookdown.org/home/, which is an ugly URL
(function() {
  var loc = window.top.location, his = window.top.history;
  if (loc.protocol !== 'https:' || /^\/(connect\/)?$/.test(loc.pathname) || !his.replaceState) return;
  // resolve relative links to absolute links, otherwise they'll be relative to /
  // after we replace state
  var i, links = document.querySelectorAll('a');
  for (i = 0; i < links.length; i++) {
    if (/^https?:\/\//.test(links[i].getAttribute('href'))) continue;
    links[i].href = links[i].href;
  }
  his.replaceState({}, '', '/');
})();
