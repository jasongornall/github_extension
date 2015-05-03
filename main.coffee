# youtube polling
# get comments
# https://gdata.youtube.com/feeds/api/videos/AJDUHq2mJx0/comments?start-index=26&max-results=25

# get # comments
# https://www.googleapis.com/youtube/v3/videos?part=statistics&id=sTPtBvcYkO8&key=AIzaSyCOgZXFd0wj49anj5THC0bJva_oNjaBilQ
# grab teacup
old_url = ''
new_url = ''
comment_listener = null
clearInterval window.urlWatchInterval if window.urlWatchInterval
window.urlWatchInterval  = setInterval ( ->
  chrome.runtime.sendMessage {
      type: 'get-config'
      config: 'disable'
  }, (data) ->
    return if data is 'true'
    new_url = window.location.href
    if (old_url != new_url)
      if executeContent()
        old_url = new_url
), 1000



executeContent = ->
  clearInterval comment_listener if comment_listener
  parseQueryString = ->
    str = window.location.search
    objURL = {}
    str.replace new RegExp('([^?=&]+)(=([^&]*))?', 'g'), ($0, $1, $2, $3) ->
      objURL[$1] = $3
      return
    objURL

  markNew = (ticket, difference) ->
    chrome.runtime.sendMessage {
      type: 'get-config'
      config: 'new'
    }, (data) ->
      return unless data is 'true'
      $el = $("li[data-issue-id='#{ticket}']")
      $el.find('.issue-title .issue-meta').append """
      <span class = 'new-comments animated fadeIn' style= 'color:purple;'>
        #{difference} new comments
      </span>
      """

  markUnread = (ticket) ->
    chrome.runtime.sendMessage {
      type: 'get-config'
      config: 'unread'
    }, (data) ->
      return unless data is 'true'
      $el = $("li[data-issue-id='#{ticket}']")
      $el.find('.issue-title .issue-meta').append """
      <span class = 'new-comments animated fadeIn' style= 'color:green;'>
        unread ticket
      </span>
      """

  markSame = (ticket) ->
    chrome.runtime.sendMessage {
      type: 'get-config'
      config: 'nochange'
    }, (data) ->
      return unless data is 'true'
      $el = $("li[data-issue-id='#{ticket}']")
      $el.find('.issue-title .issue-meta').append """
      <span class = 'new-comments animated fadeIn' style= 'color:orange;'>
        nothing changed
      </span>
      """


  teacup = window.window.teacup
  {span, div, ul, ol, li, a, h1, h3, p, iframe, raw, script, coffeescript, link, input, img} = teacup
  old_entry = null
  url = parseQueryString()
  pathname = new URL(window.location.href).pathname
  if /issues$|\/issues\/assigned\/|pulls$|\/pulls\/assigned\/|\/milestones\//.test pathname
    return false unless !!$('#js-issues-search')?.length
    query = $('#js-issues-search').val()
    repo = $('.dropdown-header > span').attr('title')

    query = query.replace(/\s/g, '+')

    query_str = "#{query}"
    per_page = 25
    page = url.page or '1'
    $('.repository-sidebar .history').remove()
    $('.repository-sidebar').append teacup.render ->
      div '.history animated fadeIn', ->
        h1 '.header', -> 'History'
        ol '.his-items', ->
          arr = JSON.parse(localStorage['history']).reverse()
          for loc in arr or []
            {title, url} = loc
            li '.hist-item', ->
              a href:url, -> title

    chrome.runtime.sendMessage {
      type: 'search-info'
      query: query_str
      repo:repo
      page: page
      per_page: per_page
      }, (data) ->
        for item in data?.items or []
          $("li[data-issue-id='#{item.number}'] .new-comments").remove()
          if not localStorage[item.html_url]
            markUnread item.number
            continue

          comments = item.comments + 1
          num = parseInt localStorage[item.html_url]

          if num < comments
            markNew(item.number, comments - num)
          else if num > comments
            # stuff got deleted
            localStorage[item.html_url] = comments
          else
            markSame item.number

    return true
  else if /issues\/\d+$|pull\/\d+$/.test pathname
    return false unless !!$('.timeline-comment-wrapper > .comment')?.length
    # don't do it for new pages
    comment_total = 0
    inject_key = =>
      key = new_url
      return unless /issues\/\d+$|pull\/\d+$/.test key
      localStorage[key] = comment_total



      # handle history
      if not localStorage['history']?.length
        localStorage['history'] = JSON.stringify({})

      # prevent dupes
      arr = JSON.parse(localStorage['history'])
      for item, index in arr
        if item.url is key
          arr.splice(index,1)
          break

      arr.push {
        title: $('.js-issue-title').text()
        url: key
      }
      arr = arr[-5..]
      localStorage['history'] = JSON.stringify arr


    comment_listener = setInterval ( ->
      new_comments = $('.timeline-comment-wrapper > .comment')?.length
      if new_comments and new_comments != comment_total
        comment_total = new_comments
        inject_key()
    ), 100


    return true
  else
    return true




