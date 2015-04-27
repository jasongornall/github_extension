# youtube polling
# get comments
# https://gdata.youtube.com/feeds/api/videos/AJDUHq2mJx0/comments?start-index=26&max-results=25

# get # comments
# https://www.googleapis.com/youtube/v3/videos?part=statistics&id=sTPtBvcYkO8&key=AIzaSyCOgZXFd0wj49anj5THC0bJva_oNjaBilQ
# grab teacup
old_url = ''
clearInterval window.urlWatchInterval if window.urlWatchInterval
window.urlWatchInterval  = setInterval ( ->
  if (old_url != window.location.href)
    executeContent()
    old_url = window.location.href
), 1000



executeContent = ->
  console.log 'CONTENT EXECUTED'
  parseQueryString = ->
    str = window.location.search
    objURL = {}
    str.replace new RegExp('([^?=&]+)(=([^&]*))?', 'g'), ($0, $1, $2, $3) ->
      objURL[$1] = $3
      return
    objURL

  markNew = (ticket, difference) ->
    console.log 'NEW'
    $el = $("li[data-issue-id='#{ticket}']")
    $el.find('.issue-title > a').append """
    <span class = 'new-comments' style= 'color:purple;'>
      #{difference} new comments
    </span>
    """


  teacup = window.window.teacup
  {span, div, a, h1, h3, p, iframe, raw, script, coffeescript, link, input, img} = teacup
  old_entry = null
  url = parseQueryString()
  console.log localStorage, 'wakka'
  search_page = !!$('#js-issues-search')?.length
  console.log 'wakka'
  if search_page
    console.log 'here'
    query = $('#js-issues-search').val()
    repo = $('head > meta[property="og:title"]').attr('content')

    query = query.replace(/\s/g, '+')

    query_str = "#{query}"
    per_page = $('[data-issue-id]').length
    page = url.page or '1'

    chrome.runtime.sendMessage {
      type: 'search-info'
      query: query_str
      repo:repo
      page: page
      per_page: per_page
      }, (data) ->
        for item in data?.items or []
          continue unless localStorage[item.html_url]
          comments = item.comments + 1
          num = parseInt localStorage[item.html_url]
          console.log num, comments, 'panda'
          $("li[data-issue-id='#{item.number}'] .new-comments").remove()
          if num < comments
            markNew(item.number, comments - num)
          else if num > comments
            # stuff got deleted
            localStorage[item.html_url] = comments
          else
            console.log 'do nothing they are equal'
  else
    # don't do it for new pages
    console.log 'WAHT'
    return if window.location.href.indexOf('issues/new') != -1
    console.log 'rrrrr'
    inject_key = =>
      console.log 'injection'
      key = window.location.href
      comments = $('.timeline-comment-wrapper > .comment')?.length
      console.log 'set', key, comments
      localStorage[key] = comments
    inject_key()

    window.addEventListener "beforeunload", (e) ->
      inject_key()




