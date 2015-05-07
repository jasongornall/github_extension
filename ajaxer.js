// Generated by CoffeeScript 1.8.0
(function() {
  chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    var conf, query, return_data, _i, _len, _ref;
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
          localStorage['new'] = 'true';
          localStorage['nochange'] = 'true';
          localStorage['unread'] = 'true';
          localStorage['user_history'] = 'true';
          localStorage['user_breakdown'] = 'true';
          localStorage['milestone_breakdown'] = 'true';
          localStorage['initialized'] = 'true';
        }
        if (Array.isArray(request.config)) {
          return_data = {};
          _ref = request.config;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            conf = _ref[_i];
            if (localStorage[conf] !== 'true') {
              continue;
            }
            return_data[conf] = localStorage[conf];
          }
          sendResponse(return_data);
        } else {
          sendResponse(localStorage[request.config]);
        }
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
