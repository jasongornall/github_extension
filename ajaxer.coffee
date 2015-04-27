chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log 'hit'
  switch request.type
    when 'user-info'
      console.log 'hit', gh
      console.log gh, '123'
      gh.xhrWithAuth 'GET', 'https://api.github.com/user', false, (error, status, response) ->
        json = JSON.parse(response)
        console.log error, status, response, 'wakka'
        sendResponse json

     when 'search-info'
      query  = "https://api.github.com/search/issues?q=#{request.query}+repo:#{request.repo}&page=#{request.page}&per_page=#{request.per_page}"
      gh.xhrWithAuth 'GET', query, false, (error, status, response) ->
        console.log error, status, response
        json = JSON.parse(response)
        sendResponse json

     when  'rate-limit'
      gh.xhrWithAuth 'GET', "https://api.github.com/rate_limit", false, (error, status, response) ->
        json = JSON.parse(response)
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


