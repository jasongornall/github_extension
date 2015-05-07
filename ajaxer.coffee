chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  switch request.type
    when 'user-info'
      gh.xhrWithAuth 'GET', 'https://api.github.com/user', true, (error, status, response) ->
        json = JSON.parse(response) if response
        if error or json?.errors
          chrome.browserAction.setIcon {path:"github-bad.png"}
          gh.revokeToken()
        else
          chrome.browserAction.setIcon {path:"github-good.png"}
          sendResponse json

     when 'search-info'
      query  = "https://api.github.com/search/issues?q=#{request.query}+repo:#{request.repo}&page=#{request.page}&per_page=#{request.per_page}"
      gh.xhrWithAuth 'GET', query, false, (error, status, response) ->
        json = JSON.parse(response) if response
        if error or json?.errors
          chrome.browserAction.setIcon {path:"github-bad.png"}
          gh.revokeToken()
        else
          chrome.browserAction.setIcon {path:"github-good.png"}
          sendResponse json


     when  'rate-limit'
      gh.xhrWithAuth 'GET', "https://api.github.com/rate_limit", false, (error, status, response) ->
        json = JSON.parse(response) if response
        if error or json?.errors
          chrome.browserAction.setIcon {path:"github-bad.png"}
          gh.revokeToken()
        else
          chrome.browserAction.setIcon {path:"github-good.png"}
          sendResponse json

    when 'set-config'
      localStorage[request.config] = request.val
      sendResponse {}

    when 'get-config'
      if localStorage['initialized'] != 'true'
        localStorage['new'] = 'true'
        localStorage['nochange'] = 'true'
        localStorage['unread'] = 'true'
        localStorage['user_history'] = 'true'
        localStorage['user_breakdown'] = 'true'
        localStorage['milestone_breakdown'] = 'true'
        localStorage['initialized'] = 'true'
        localStorage['label_breakdown'] = 'true'
      if Array.isArray request.config
        return_data = {}
        for conf in request.config
          continue unless localStorage[conf] == 'true'
          return_data[conf] = localStorage[conf]
        sendResponse return_data
      else
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

