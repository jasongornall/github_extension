chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log 'hit', gh
  switch request.type
    when 'user-info'
      gh.xhrWithAuth 'GET', 'https://api.github.com/user', true, (error, status, response) ->
        json = JSON.parse(response)
        if error
          chrome.browserAction.setIcon {path:"github-bad.png"}
          sendResponse {error: error}
        else
          sendResponse json

     when 'search-info'
      query  = "https://api.github.com/search/issues?q=#{request.query}+repo:#{request.repo}&page=#{request.page}&per_page=#{request.per_page}"
      gh.xhrWithAuth 'GET', query, false, (error, status, response) ->
        json = JSON.parse(response)
        if error
          chrome.browserAction.setIcon {path:"github-bad.png"}
        else
          sendResponse json

     when  'rate-limit'
      gh.xhrWithAuth 'GET', "https://api.github.com/rate_limit", false, (error, status, response) ->
        json = JSON.parse(response)
        if error
          chrome.browserAction.setIcon {path:"github-bad.png"}
        else
          sendResponse json

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


