renderUser =  ->
  chrome.runtime.sendMessage {
    type: 'user-info'
    interactive: false
  }, (user_info) ->
    if not user_info.error
      $('#signin').hide()
      $('#revoke').show()

      $('#user').html """
        <div>
          <span class="name">Logged in as: #{user_info.login}</span>
          <img src="#{user_info.avatar_url}"/>
        </div>
      """
    else
      $('#signin').show()
      $('#revoke').hide()
      $('#user').html """
        <div>
          <span class="name">Error detected: </span>
          <span class="error">#{user_info.error}</span>
        </div>
      """


$(document).ready ->
  gh.tokenFetcher.getToken false, (error, access_token) ->
    console.log access_token, 'PANDA'
    $('#signin').on 'click', (e)->
      gh.interactiveSignIn ->
        $('#signin').hide()
        $('#revoke').show()
        chrome.browserAction.setIcon {path:"github-good.png"}
        renderUser()

    $('#revoke').on 'click', (e)->
      gh.revokeToken()
      $('#user').empty()
      $('#signin').show()
      $('#revoke').hide()

    if access_token
      $('#user').empty()
      $('#signin').hide()
      $('#revoke').show()
      renderUser()
    else
      $('#user').empty()
      $('#signin').show()
      $('#revoke').hide()


