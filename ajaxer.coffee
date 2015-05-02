chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log 'hit', request
  switch request.type
    when 'user-info'
      gh.xhrWithAuth 'GET', 'https://api.github.com/user', true, (error, status, response) ->
        if error or response.errors
          chrome.browserAction.setIcon {path:"github-bad.png"}
          gh.revokeToken()
        else
          json = JSON.parse(response)
          chrome.browserAction.setIcon {path:"github-good.png"}
          sendResponse json

     when 'search-info'
      query  = "https://api.github.com/search/issues?q=#{request.query}+repo:#{request.repo}&page=#{request.page}&per_page=#{request.per_page}"
      console.log query, 'panda'
      gh.xhrWithAuth 'GET', query, false, (error, status, response) ->
        if error or response.errors
          chrome.browserAction.setIcon {path:"github-bad.png"}
          gh.revokeToken()
        else
          json = JSON.parse(response)
          console.log json, '12'
          chrome.browserAction.setIcon {path:"github-good.png"}
          sendResponse json

     when  'rate-limit'
      gh.xhrWithAuth 'GET', "https://api.github.com/rate_limit", false, (error, status, response) ->
        if error or response.errors
          chrome.browserAction.setIcon {path:"github-bad.png"}
          gh.revokeToken()
        else
          json = JSON.parse(response)
          chrome.browserAction.setIcon {path:"github-good.png"}
          sendResponse json

    when 'set-config'
      localStorage[request.config] = request.val
      sendResponse {}

    when 'get-config'
      sendResponse localStorage[request.config]

    when 'get-token'
      gh.tokenFetcher.getToken false, (error, access_token) ->
        sendResponse {
          error: error
          access_token: access_token
        }

    when 'revoke-token'
      gh.revokeToken()
      sendResponse {}

  return true


### neat idea maybe later
chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  return unless (changeInfo.status == "loading")

  if(/^https?:\/\/github\.com.+\/issues/.test(tab.url))
    console.log 'inside'
    chrome.pageAction.setIcon({tabId: tabId, path:"github-green.png"})
  else
    console.log 'outside'
    chrome.pageAction.setIcon({tabId: tabId, path:"github-128.png"})
###


