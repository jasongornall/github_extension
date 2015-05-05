gh = do ->
  error = ''
  xhrWithAuth = (method, url, interactive, callback) ->
    retry = true
    access_token = undefined

    getToken = ->
      tokenFetcher.getToken interactive, (error, token) ->
        if error
          callback error
          return
        access_token = token
        requestStart()
        return
      return

    requestStart = ->
      xhr = new XMLHttpRequest
      xhr.open method, url
      xhr.setRequestHeader 'Authorization', 'Bearer ' + access_token
      xhr.onload = requestComplete
      xhr.send()
      return

    requestComplete = ->
      if (@status < 200 or @status >= 300) and retry
        retry = false
        tokenFetcher.removeCachedToken access_token
        access_token = null
        getToken()
      else
        callback null, @status, @response
      return

    getToken()
    return

  getUserInfo = (interactive) ->
    xhrWithAuth 'GET', 'https://api.github.com/user', interactive, onUserInfoFetched
    return

  # Functions updating the User Interface:

  showButton = (button) ->
    button?.style.display = 'inline'
    button?.disabled = false
    return

  handleError = (error) ->

  disableButton = (button) ->
    button?.disabled = true
    return

  onUserInfoFetched = (error, status, response) ->
    if !error and status == 200
      user_info = JSON.parse(response)
      populateUserInfo user_info
      fetchUserRepos user_info['repos_url']
    else
      handleError error
    return

  populateUserInfo = (user_info) ->
    elem = user_info_div
    nameElem = document.createElement('div')
    nameElem.innerHTML = '<b>Hello ' + user_info.name + '</b><br>' + 'Your github page is: ' + user_info.html_url
    elem?.appendChild nameElem
    return

  fetchUserRepos = (repoUrl) ->
    xhrWithAuth 'GET', repoUrl, false, onUserReposFetched
    return

  onUserReposFetched = (error, status, response) ->
    if !error and status == 200
      user_repos = JSON.parse(response)
      user_repos.forEach (repo) ->
        if repo.private
          elem.value += '[private repo]'
        else
          elem.value += repo.name
        elem.value += '\n'
        return
    else
    return

  # Handlers for the buttons's onclick events.

  interactiveSignIn = (next) ->
    disableButton signin_button
    tokenFetcher.getToken true, (error, access_token) ->
      next error, access_token

  revokeToken = ->
    # We are opening the web page that allows user to revoke their token.
    # And then clear the user interface, showing the Sign in button only.
    # If the user revokes the app authorization, they will be prompted to log
    # in again. If the user dismissed the page they were presented with,
    # Sign in button will simply sign them in.
    localStorage.removeItem('access_token')
    tokenFetcher.getToken false, (error, access_token) ->
      tokenFetcher.removeCachedToken access_token

    return

  'use strict'
  signin_button = undefined
  revoke_button = undefined
  user_info_div = undefined
  tokenFetcher = do ->
    # Replace clientId and clientSecret with values obtained by you for your
    # application https://github.com/settings/applications.
    clientId = '11442b0924c8d6a98fb7'
    clientSecret = 'a1499b1a5780c8a21ed560b839741e803c4cc936'
    redirectUri = chrome.identity.getRedirectURL('provider_cb')
    redirectRe = new RegExp(redirectUri + '[#?](.*)')
    access_token = null
    {
      getToken: (interactive, callback) ->
        # In case we already have an access_token cached, simply return it.

        parseRedirectFragment = (fragment) ->
          pairs = fragment.split(/&/)
          values = {}
          pairs.forEach (pair) ->
            nameval = pair.split(RegExp('='))
            values[nameval[0]] = nameval[1]
            return
          values

        handleProviderResponse = (values) ->
          if values.hasOwnProperty('access_token')
            setAccessToken values.access_token
          else if values.hasOwnProperty('code')
            exchangeCodeForToken values.code
          else
            callback new Error('Neither access_token nor code avialable.')
          return

        exchangeCodeForToken = (code) ->
          xhr = new XMLHttpRequest
          xhr.open 'GET', 'https://github.com/login/oauth/access_token?' + 'client_id=' + clientId + '&client_secret=' + clientSecret + '&redirect_uri=' + redirectUri + '&code=' + code + '&scope=user,repo'
          xhr.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded'
          xhr.setRequestHeader 'Accept', 'application/json'

          xhr.onload = ->
            # When exchanging code for token, the response comes as json, which
            # can be easily parsed to an object.
            if @status == 200
              response = JSON.parse(@responseText)
              if response.hasOwnProperty('access_token')
                setAccessToken response.access_token
              else
                callback new Error('Cannot obtain access_token from code.')
            else
              callback new Error('Code exchange failed')
            return

          xhr.send()
          return

        setAccessToken = (token) ->
          access_token = token
          localStorage['access_token'] = token
          callback null, access_token
          return

        access_token ?= localStorage['access_token']
        if access_token
          callback null, access_token
          return
        options =
          'interactive': interactive
          'url': 'https://github.com/login/oauth/authorize' + '?client_id=' + clientId + '&redirect_uri=' + encodeURIComponent(redirectUri) + '&scope=user,repo'
        chrome.identity.launchWebAuthFlow options, (redirectUri) ->
          if chrome.runtime.lastError
            callback new Error(chrome.runtime.lastError)
            return
          # Upon success the response is appended to redirectUri, e.g.
          # https://{app_id}.chromiumapp.org/provider_cb#access_token={value}
          #     &refresh_token={value}
          # or:
          # https://{app_id}.chromiumapp.org/provider_cb#code={value}
          matches = redirectUri.match(redirectRe)
          if matches and matches.length > 1
            handleProviderResponse parseRedirectFragment(matches[1])
          else
            callback new Error('Invalid redirect URI')
          return
        return
      removeCachedToken: (token_to_remove) ->
        if access_token == token_to_remove
          localStorage.removeItem('access_token')
          access_token = null
        return

    }
  {
    error: error
    tokenFetcher: tokenFetcher
    revokeToken: revokeToken
    xhrWithAuth: xhrWithAuth
    interactiveSignIn: interactiveSignIn
    revokeToken: revokeToken
    getUserInfo: getUserInfo
    onload: ->
      ###
      signin_button = document.querySelector('#signin');
      signin_button?.onclick = interactiveSignIn;

      revoke_button = document.querySelector('#revoke');
      revoke_button?.onclick = revokeToken;

      user_info_div = document.querySelector('#user_info');


      showButton(signin_button);
      getUserInfo(false);
      ###

 }
 window.gh = gh;

# ---
# generated by js2coffee 2.0.3
