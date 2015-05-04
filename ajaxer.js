// Generated by CoffeeScript 1.8.0
(function() {
  chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    var query;
    console.log('a');
    switch (request.type) {
      case 'user-info':
        gh.xhrWithAuth('GET', 'https://api.github.com/user', true, function(error, status, response) {
          var json;
          if (response) {
            json = JSON.parse(response);
          }
          if (error || (json != null ? json.errors : void 0)) {
            chrome.browserAction.setIcon({
              path: "github-bad.png"
            });
            return gh.revokeToken();
          } else {
            chrome.browserAction.setIcon({
              path: "github-good.png"
            });
            return sendResponse(json);
          }
        });
        break;
      case 'search-info':
        query = "https://api.github.com/search/issues?q=" + request.query + "+repo:" + request.repo + "&page=" + request.page + "&per_page=" + request.per_page;
        console.log(query, 'panda');
        gh.xhrWithAuth('GET', query, false, function(error, status, response) {
          var json;
          if (response) {
            json = JSON.parse(response);
          }
          if (error || (json != null ? json.errors : void 0)) {
            chrome.browserAction.setIcon({
              path: "github-bad.png"
            });
            return gh.revokeToken();
          } else {
            chrome.browserAction.setIcon({
              path: "github-good.png"
            });
            return sendResponse(json);
          }
        });
        break;
      case 'rate-limit':
        gh.xhrWithAuth('GET', "https://api.github.com/rate_limit", false, function(error, status, response) {
          var json;
          if (response) {
            json = JSON.parse(response);
          }
          if (error || (json != null ? json.errors : void 0)) {
            chrome.browserAction.setIcon({
              path: "github-bad.png"
            });
            return gh.revokeToken();
          } else {
            chrome.browserAction.setIcon({
              path: "github-good.png"
            });
            return sendResponse(json);
          }
        });
        break;
      case 'set-config':
        localStorage[request.config] = request.val;
        sendResponse({});
        break;
      case 'get-config':
        if (localStorage['initialized'] !== 'true') {
          localStorage['new'] = 'false';
          localStorage['nochange'] = 'false';
          localStorage['unread'] = 'true';
          localStorage['initialized'] = 'true';
        }
        sendResponse(localStorage[request.config]);
        break;
      case 'get-token':
        gh.tokenFetcher.getToken(false, function(error, access_token) {
          return sendResponse({
            error: error,
            access_token: access_token
          });
        });
        break;
      case 'revoke-token':
        gh.revokeToken();
        sendResponse({});
    }
    return true;
  });

}).call(this);
