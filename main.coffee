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
  # handle history
  if not localStorage['history']?.length
    localStorage['history'] = JSON.stringify([])

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
  injectHistory = ->
    chrome.runtime.sendMessage {
      type: 'get-config'
      config: 'user_history'
    }, (data) ->
      return unless data is 'true'
      $('.repository-sidebar').append teacup.render ->
        div '.history animated fadeIn', ->
          h1 '.header', -> "Issue History for You"
          ol '.his-items', ->
            arr = JSON.parse(localStorage['history']).reverse()
            for loc in arr or []
              {title, url} = loc
              li '.hist-item', ->
                a href:url, -> title

  injectPieChart = ->
    chrome.runtime.sendMessage {
      type: 'get-config'
      config: 'user_breakdown'
    }, (data) ->
      return unless data is 'true'
      t = new Date()
      dayCount = t.getDay()
      if dayCount is 0
        dayCount = 7
      t.setDate t.getDate() - dayCount
      t.setHours(0,0,0,0)
      created = t.toISOString().substr(0, 10)
      query_issues = "closed:>#{created} is:issue"
      chrome.runtime.sendMessage {
        type: 'search-info'
        query: query_issues
        repo:repo
        page: 1
        per_page: 1000
      }, (issues_data) ->
        $('.repository-sidebar').append teacup.render ->
          div '.issues-closed animated fadeIn', ->
            h1 '.header', -> "Issues closed this week by user for #{repo}"
            canvas '.canvas', 'width': '180', 'height': '180'
            div '.legend'

        ctx = $('.repository-sidebar .issues-closed .canvas').get(0).getContext('2d')

        user_data = []
        config_data = {}
        config_index = -1
        for item in issues_data?.items
          continue unless item.assignee?.login
          if config_data[item.assignee.login] is undefined
            config_index++
            config_data[item.assignee.login] = config_index
          user_index = config_data[item.assignee.login]

          user_data[user_index] ?= {
            value: 0
            color: window.colors[user_index]
            highlight: window.colors[user_index]
            label: item.assignee.login
          }
          user_data[user_index].value++

        user_data.sort (a, b) ->
          return b.value - a.value

        myPieChart = new Chart(ctx).Pie user_data, {
          legendTemplate: """
            <ol class=\ "<%=name.toLowerCase()%>-legend\">
                <% for (var i=0; i<segments.length; i++){%>
                    <li class=\ "<%=segments[i].label%>\" style=\ "color:<%=segments[i].fillColor%>\" >
                      <span>
                        <%if(segments[i].label){%>
                            <%=segments[i].label%>
                                <%}%>
                      </span>
                    </li>
                    <%}%>
            </ol>
          """
          animateRotate : false
        }
        $legend = $('.repository-sidebar .issues-closed .legend')
        $legend.html myPieChart.generateLegend()
        legendHolder = $legend[0]

        $legend.find('.pie-legend li').on 'click', (e) ->
          $el = $ e.currentTarget
          assignee = $el.find('span').text().trim()
          $('#js-issues-search').val("closed:>#{created} assignee:#{assignee} is:issue")
          $('#js-issues-search').closest('form').submit()

        helpers = Chart.helpers;
        helpers.each $legend.find('.pie-legend').children(), (legendNode, index) ->
          helpers.addEvent legendNode, 'mouseover', ->

            activeSegment = myPieChart.segments[index]
            activeSegment.save()
            myPieChart.showTooltip [ activeSegment ]
            activeSegment.restore()
            return
          return
        helpers.addEvent $legend[0], 'mouseleave', ->
          myPieChart.draw()
          return
        $('.repository-sidebar .issues-closed .canvas').on 'click', (e) ->
          activePoints = myPieChart.getSegmentsAtEvent(e)
          label = activePoints[0]?.label
          $(".repository-sidebar .issues-closed .#{label}").click()



  teacup = window.window.teacup
  {span, canvas,  div, ul, ol, li, a, h1, h3, p, iframe, raw, script, coffeescript, link, input, img} = teacup
  old_entry = null
  url = parseQueryString()
  pathname = new URL(window.location.href).pathname

  $('.repository-sidebar .issues-closed').remove()
  $('.repository-sidebar .history').remove()

  if /issues$|\/issues\/assigned\/|pulls$|\/pulls\/assigned\/|\/milestones\//.test pathname
    console.log 'issues found'
    return false unless !!$('#js-issues-search')?.length
    query = $('#js-issues-search').val()
    repo = $('.dropdown-header > span').attr('title')

    query = query.replace(/\s/g, '+')

    query_str = "#{query}"
    per_page = 25
    page = url.page or '1'

    injectHistory()
    # canvas test
    if /issues$|\/issues\/assigned\/|\/milestones\//.test pathname
      injectPieChart()

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
    console.log 'issue found'
    # don't do it for new pages
    comment_total = 0
    inject_key = =>
      key = new_url
      return unless /issues\/\d+$|pull\/\d+$/.test key
      localStorage[key] = comment_total

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




