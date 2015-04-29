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

    $('#navigation > div').on 'click', (e) ->
      $nav = $ e.currentTarget
      cls = $nav.attr('class')
      $nav.closest('body').attr('class', cls)


    $('.nav.config > input').on 'click', (e) ->
      $check = $ e.currentTarget
      val = $check.val()
      chrome.runtime.sendMessage {
        type: 'set-config'
        config: val
        val: $check.is(':checked')
      }

    for el in $('.nav.config > input')
      do ->
        $el = $(el)
        val = $el.val()
        chrome.runtime.sendMessage {
          type: 'get-config'
          config: val
        }, (data) ->
          console.log data, 'PANDA'
          $el.prop('checked', data is 'true' or false);

