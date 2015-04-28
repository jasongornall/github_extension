gh.tokenFetcher.getToken true, (error, access_token) ->
  signin_button = document.querySelector('#signin');
  signin_button?.onclick = gh.interactiveSignIn;

  revoke_button = document.querySelector('#revoke');
  revoke_button?.onclick = gh.revokeToken;

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
