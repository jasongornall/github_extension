// Generated by CoffeeScript 1.8.0
(function() {
  chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    var query;
    console.log('hit', request);
    switch (request.type) {
      case 'user-info':
        gh.xhrWithAuth('GET', 'https://api.github.com/user', true, function(error, status, response) {
          var json;
          if (error || response.errors) {
            chrome.browserAction.setIcon({
              path: "github-bad.png"
            });
            return gh.revokeToken();
          } else {
            json = JSON.parse(response);
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
          if (error || response.errors) {
            chrome.browserAction.setIcon({
              path: "github-bad.png"
            });
            return gh.revokeToken();
          } else {
            json = JSON.parse(response);
            console.log(json, '12');
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
          if (error || response.errors) {
            chrome.browserAction.setIcon({
              path: "github-bad.png"
            });
            return gh.revokeToken();
          } else {
            json = JSON.parse(response);
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


  /* neat idea maybe later
  chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
    return unless (changeInfo.status == "loading")
  
    if(/^https?:\/\/github\.com.+\/issues/.test(tab.url))
      console.log 'inside'
      chrome.pageAction.setIcon({tabId: tabId, path:"github-green.png"})
    else
      console.log 'outside'
      chrome.pageAction.setIcon({tabId: tabId, path:"github-128.png"})
   */

}).call(this);
