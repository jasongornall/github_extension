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

getDate = (date) ->
  breakdown = date.match(/(\d+)/g)
  return new Date(breakdown[0],parseInt(breakdown[1])-1,breakdown[2])

hexToRgb = (hex) ->
  result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  if result
    r: parseInt(result[1], 16)
    g: parseInt(result[2], 16)
    b: parseInt(result[3], 16)
  else
    null

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
      console.log 'wakka'
      $('.protip').append teacup.render ->
        div '.history animated fadeIn', ->
          h1 '.header', -> "Last 5 Issues Viewed"
          ol '.his-items', ->
            arr = JSON.parse(localStorage['history']).reverse()
            for loc in arr or []
              {title, url} = loc
              li '.hist-item', ->
                a href:url, -> title

  injectBarGraph = (el, data) ->
    chrome.runtime.sendMessage {
      type: 'get-config'
      config: ["user_total_open","user_total_closed", "weekly_total"]
    }, (data_configs) =>
      return unless Object.keys(data_configs).length
      $('.protip').append teacup.render ->
        div ".#{el}", ->
          h1 "Weekly Breakdown"
          div '.total-issues', ->
            h1 '.header', -> "Total Issues Closed/Opened"
            canvas '.canvas', 'width': '920', 'height': '180'
            div '.legend'
          div '.user-closed', ->
            h1 '.header', -> "User Issues Closed"
            canvas '.canvas', 'width': '920', 'height': '180'
            div '.legend'
          div '.user-opened', ->
            h1 '.header', -> "User Issues Opened"
            canvas '.canvas', 'width': '920', 'height': '180'
            div '.legend'


      do ->
        if data_configs?.weekly_total != 'true'
          $(".protip .#{el} .total-issues").remove()
          return
        ctx = $(".protip .#{el} .total-issues .canvas").get(0).getContext('2d')

        {closed, open} = data

        color = hexToRgb window.colors[0]
        color_2 = hexToRgb window.colors[1]
        chart_data = {
          labels: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
          datasets: [
              {
                  label: "Issues Opened",
                  fillColor: "rgba(#{color.r},#{color.g},#{color.b},0.2)",
                  strokeColor: "rgba(#{color.r},#{color.g},#{color.b},1)",
                  pointColor: "rgba(#{color.r},#{color.g},#{color.b},1)",
                  pointStrokeColor: "rgba(#{color.r},#{color.g},#{color.b},1)",
                  data: [0, 0, 0, 0, 0, 0, 0]
              },
              {
                  label: "Issues Closed",
                  fillColor: "rgba(#{color_2.r},#{color_2.g},#{color_2.b},0.2)",
                  strokeColor: "rgba(#{color_2.r},#{color_2.g},#{color_2.b},1)",
                  pointColor: "rgba(#{color_2.r},#{color_2.g},#{color_2.b},1)",
                  pointStrokeColor: "rgba(#{color_2.r},#{color_2.g},#{color_2.b},1)",
                  data: [0, 0, 0, 0, 0, 0, 0]
              }
          ]
        }

        for item in open?.items or []
          date = getDate item.created_at
          day = date.getDay()

          chart_data.datasets[0].data[day]++

        for item in closed?.items or []
          date = getDate item.closed_at
          day = date.getDay()

          chart_data.datasets[1].data[day]++

        myPieChart = new Chart(ctx).BarOneTip chart_data, {
          tooltipTemplate: "<%if (datasetLabel){%><%=datasetLabel%>: <%}%><%= value %>",
          legendTemplate : """
            <ul class=\ "<%=name.toLowerCase()%>-legend\">
              <% for (var i=0; i<datasets.length; i++){%>
                <div style=\ "background-color:<%=datasets[i].fillColor%>;border: 1px solid <%=datasets[i].strokeColor%>;padding:1px;\">
                  <%if(datasets[i].label){%>
                      <%=datasets[i].label%>
                  <%}%>
                </div>
              <%}%>
            </ul>
          """
        }

        $legend = $(".protip .#{el} .total-issues .legend")
        $legend.html myPieChart.generateLegend()
        $(".protip .#{el} .total-issues .canvas").click (e) ->

          activeBars = myPieChart.getBarsAtEvent(e)
          eventData = Chart.helpers.getRelativePosition(e)
          currentBar = null
          for bar in activeBars
            if bar.inRange(eventData.x, eventData.y)
              currentBar = bar

          return unless currentBar
          current_label = currentBar.label
          labels = myPieChart.scale.xLabels
          t = new Date()
          dayCount = labels.indexOf(current_label)
          t.setDate t.getDate() - (t.getDay() - dayCount)
          t.setHours(0,0,0,0)
          created = t.toISOString().substr(0, 10)

          assignee = currentBar.datasetLabel
          if assignee is 'Issues Opened'
            query = "created:#{created}"
          else
            query = "closed:#{created}"

          $('#js-issues-search').val("#{query} is:issue")
          $('#js-issues-search').closest('form').submit()
          return

      do ->
        if data_configs?.user_total_closed != 'true'
          $(".protip .#{el} .user-closed").remove()
          return
        ctx = $(".protip .#{el} .user-closed .canvas").get(0).getContext('2d')

        {closed} = data

        chart_data = {
          labels: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
          datasets: {
          }
        }


        color_index = 0
        for item in closed?.items or []
          date = getDate item.closed_at
          day = date.getDay()

          user = item.assignee?.login or 'unassigned'
          if not chart_data.datasets[user]
            color = hexToRgb window.colors[color_index]
            chart_data.datasets[user] = {
              label: "#{user}",
              fillColor: "rgba(#{color.r},#{color.g},#{color.b},0.2)",
              strokeColor: "rgba(#{color.r},#{color.g},#{color.b},1)",
              pointColor: "rgba(#{color.r},#{color.g},#{color.b},1)",
              pointStrokeColor: "rgba(#{color.r},#{color.g},#{color.b},1)",
              pointHighlightFill: "#fff",
              pointHighlightStroke: "rgba(151,187,205,1)",
              data: [0, 0, 0, 0, 0, 0, 0]
            }
            color_index++
          chart_data.datasets[user].data[day]++

        myPieChart = new Chart(ctx).BarOneTip chart_data, {
          tooltipTemplate: "<%if (datasetLabel){%><%=datasetLabel%>: <%}%><%= value %>",
          pointDot : false
          legendTemplate : """
            <div class=\ "<%=name.toLowerCase()%>-legend\">
              <% for (var i=0; i<datasets.length; i++){%>
                  <div style=\ "background-color:<%=datasets[i].fillColor%>;border: 1px solid <%=datasets[i].strokeColor%>;padding:1px;\">
                    <%if(datasets[i].label){%>
                        <%=datasets[i].label%>
                    <%}%>
                  </div>
              <%}%>
            </div>
          """
        }

        $legend = $(".protip .#{el} .user-closed .legend")
        $legend.html myPieChart.generateLegend()

        $(".protip .#{el} .user-closed .canvas").click (e) ->

          activeBars = myPieChart.getBarsAtEvent(e)
          eventData = Chart.helpers.getRelativePosition(e)
          currentBar = null
          for bar in activeBars
            if bar.inRange(eventData.x, eventData.y)
              currentBar = bar

          return unless currentBar
          current_label = currentBar.label
          labels = myPieChart.scale.xLabels
          t = new Date()
          dayCount = labels.indexOf(current_label)
          t.setDate t.getDate() - (t.getDay() - dayCount)
          t.setHours(0,0,0,0)
          created = t.toISOString().substr(0, 10)

          assignee = currentBar.datasetLabel
          if assignee is 'unassigned'
            assignee = 'no:assignee'
          else
            assignee = "assignee:#{assignee}"

          $('#js-issues-search').val("closed:#{created} #{assignee} is:issue")
          $('#js-issues-search').closest('form').submit()
          return

      do ->
        if data_configs?.user_total_open != 'true'
          $(".protip .#{el} .user-opened").remove()
          return
        ctx = $(".protip .#{el} .user-opened .canvas").get(0).getContext('2d')

        {open} = data

        chart_data = {
          labels: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
          datasets: {
          }
        }

        color_index = 0
        for item in open?.items or []
          date = getDate item.created_at
          day = date.getDay()

          user = item.assignee?.login or 'unassigned'
          if not chart_data.datasets[user]
            color = hexToRgb window.colors[color_index]
            chart_data.datasets[user] = {
              label: "#{user}",
              fillColor: "rgba(#{color.r},#{color.g},#{color.b},0.2)",
              strokeColor: "rgba(#{color.r},#{color.g},#{color.b},1)",
              pointColor: "rgba(#{color.r},#{color.g},#{color.b},1)",
              pointStrokeColor: "rgba(#{color.r},#{color.g},#{color.b},1)",
              pointHighlightFill: "#fff",
              pointHighlightStroke: "rgba(151,187,205,1)",
              data: [0, 0, 0, 0, 0, 0, 0]
            }
            color_index++
          chart_data.datasets[user].data[day]++

        myPieChart = new Chart(ctx).BarOneTip chart_data, {
          tooltipTemplate: "<%if (datasetLabel){%><%=datasetLabel%>: <%}%><%= value %>",
          legendTemplate : """
            <div class=\ "<%=name.toLowerCase()%>-legend\">
              <% for (var i=0; i<datasets.length; i++){%>
                  <div style=\ "background-color:<%=datasets[i].fillColor%>;border: 1px solid <%=datasets[i].strokeColor%>;padding:1px;\">
                    <%if(datasets[i].label){%>
                        <%=datasets[i].label%>
                    <%}%>
                  </div>
              <%}%>
            </div>
          """
        }
        $legend = $(".protip .#{el} .user-opened .legend")
        $legend.html myPieChart.generateLegend()


        $(".protip .#{el} .user-opened .canvas").click (e) ->
          console.log 'HIT'
          activeBars = myPieChart.getBarsAtEvent(e)
          eventData = Chart.helpers.getRelativePosition(e)
          currentBar = null
          for bar in activeBars
            if bar.inRange(eventData.x, eventData.y)
              currentBar = bar

          return unless currentBar
          current_label = currentBar.label
          labels = myPieChart.scale.xLabels
          t = new Date()
          dayCount = labels.indexOf(current_label)
          t.setDate t.getDate() - (t.getDay() - dayCount)
          t.setHours(0,0,0,0)
          created = t.toISOString().substr(0, 10)

          assignee = currentBar.datasetLabel
          if assignee is 'unassigned'
            assignee = 'no:assignee'
          else
            assignee = "assignee:#{assignee}"

          console.log "created:#{created}"

          $('#js-issues-search').val("created:#{created} #{assignee} is:issue")
          $('#js-issues-search').closest('form').submit()
          return


  injectPieChart = (el, closed, next) ->
    if closed
      query_base = "closed"
    else
      query_base = "created"
    chrome.runtime.sendMessage {
      type: 'get-config'
      config: ["user_breakdown_#{query_base}","milestone_breakdown_#{query_base}", "label_breakdown_#{query_base}"]
    }, (data_configs) =>
      $(".protip > .#{el}").remove()
      return unless Object.keys(data_configs).length
      t = new Date()
      dayCount = t.getDay()

      t.setDate t.getDate() - dayCount
      t.setHours(0,0,0,0)
      created = t.toISOString().substr(0, 10)
      query_issues = "#{query_base}:>#{created} is:issue"
      chrome.runtime.sendMessage {
        type: 'search-info'
        query: query_issues
        repo:repo
        page: 1
        per_page: 1000
      }, (issues_data) ->
        return next {} unless issues_data?.items?.length
        $('.protip').append teacup.render ->
          div ".#{el}", ->
            h1 "#{issues_data?.items?.length} Issues #{query_base.toUpperCase()} this week for #{repo}"
            div '.issues-closed animated fadeIn', ->
              h1 '.header', -> "User Breakdown"
              canvas '.canvas', 'width': '180', 'height': '180'
              div '.legend', -> 'loading...'
            div '.milestone-breakdown animated fadeIn', ->
              h1 '.header', -> "Milestone Breakdown"
              canvas '.canvas', 'width': '180', 'height': '180'
              div '.legend', -> 'loading...'

            div '.label-breakdown animated fadeIn', ->
              h1 '.header', -> "Label Breakdown"
              canvas '.canvas', 'width': '180', 'height': '180'
              div '.legend', -> 'loading...'

        ctx = $(".protip .#{el} .issues-closed .canvas").get(0).getContext('2d')


        ### breakup issues by user ###
        do ->
          if data_configs["user_breakdown_#{query_base}"] isnt 'true'
            $(".#{el} > .issues-closed").remove()
            return
          user_data = []
          config_data = {}
          config_index = -1
          for item in issues_data?.items
            item.assignee ?= {login:'unassigned'}
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
                      <li class=\ "val_<%=segments[i].fillColor.split('#').join('')%>\" style=\ "color:<%=segments[i].fillColor%>\" >
                        <span>
                          <%if(segments[i].label){%>
                              <%=segments[i].label%>
                                  <%}%>
                        </span>
                      </li>
                      <%}%>
              </ol>
            """
          }
          $legend = $(".protip .#{el} .issues-closed .legend")
          $legend.html myPieChart.generateLegend()
          legendHolder = $legend[0]

          $legend.find('.pie-legend li').on 'click', (e) ->
            console.log 'INSIDE'
            $el = $ e.currentTarget
            assignee = $el.find('span').text().trim()
            if assignee is 'unassigned'
              assignee = 'no:assignee'
            else
              assignee = "assignee:#{assignee}"
            $('#js-issues-search').val("#{query_base}:>#{created} #{assignee} is:issue")
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
          $(".protip .#{el} .issues-closed .canvas").on 'click', (e) ->
            activePoints = myPieChart.getSegmentsAtEvent(e)
            label = activePoints[0]?.fillColor.split('#').join('')
            $(".protip .#{el} .issues-closed .val_#{label}").click()


        ### breakup issues by Milestone ###
        do ->
          if data_configs["milestone_breakdown_#{query_base}"] isnt 'true'
            $(".#{el} > .milestone-breakdown").remove()
            return
          ctx = $(".protip .#{el} .milestone-breakdown .canvas").get(0).getContext('2d')
          milestone_data = []
          config_data = {}
          config_index = -1
          for item in issues_data?.items
            item.milestone ?= {title:'no milestone'}
            if config_data[item.milestone.title] is undefined
              config_index++
              config_data[item.milestone.title] = config_index
            milestone_index = config_data[item.milestone.title]

            milestone_data[milestone_index] ?= {
              value: 0
              color: window.colors[milestone_index]
              highlight: window.colors[milestone_index]
              label: item.milestone.title
            }
            milestone_data[milestone_index].value++
          milestone_data.sort (a, b) ->
            return b.value - a.value

          myPieChart = new Chart(ctx).Pie milestone_data, {
            legendTemplate: """
              <ol class=\ "<%=name.toLowerCase()%>-legend\">
                  <% for (var i=0; i<segments.length; i++){%>
                      <li class=\ "val_<%=segments[i].fillColor.split('#').join('')%>\" style=\ "color:<%=segments[i].fillColor%>\" >
                        <span>
                          <%if(segments[i].label){%>
                              <%=segments[i].label%>
                                  <%}%>
                        </span>
                      </li>
                      <%}%>
              </ol>
            """
          }
          $legend = $(".protip .#{el} .milestone-breakdown .legend")
          $legend.html myPieChart.generateLegend()
          legendHolder = $legend[0]

          $legend.find('.pie-legend li').on 'click', (e) ->
            $el = $ e.currentTarget
            milestone = $el.find('span').text().trim()
            if milestone is 'no milestone'
              milestone = 'no:milestone'
            else
              milestone = "milestone:\"#{milestone}\""
            $('#js-issues-search').val("#{query_base}:>#{created} #{milestone} is:issue")
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
          $(".protip .#{el} .milestone-breakdown .canvas").on 'click', (e) ->
            activePoints = myPieChart.getSegmentsAtEvent(e)
            label = activePoints[0]?.fillColor.split('#').join('')
            $(".protip .#{el} .milestone-breakdown .val_#{label}").click()

        ### breakup issues by Label ###
        do ->
          if data_configs["label_breakdown_#{query_base}"] isnt 'true'
            $(".#{el} > .label-breakdown").remove()
            return
          ctx = $(".protip .#{el} .label-breakdown .canvas").get(0).getContext('2d')
          milestone_data = []
          config_data = {}
          config_index = -1
          for item in issues_data?.items
            if not item.labels?.length
              item.labels = [{name:'no label',color:'000000'}]

            for label in item.labels
              if config_data[label.name] is undefined
                config_index++
                config_data[label.name] = config_index
              label_index = config_data[label.name]

              milestone_data[label_index] ?= {
                value: 0
                color: window.colors[label_index]
                highlight: window.colors[label_index]
                label: label.name
              }
              milestone_data[label_index].value++
          milestone_data.sort (a, b) ->
            return b.value - a.value

          myPieChart = new Chart(ctx).Pie milestone_data, {
            legendTemplate: """
              <ol class=\ "<%=name.toLowerCase()%>-legend\">
                  <% for (var i=0; i<segments.length; i++){%>
                      <li class=\ "val_<%=segments[i].fillColor.split('#').join('')%>\" style=\ "color:<%=segments[i].fillColor%>\" >
                        <span>
                          <%if(segments[i].label){%>
                              <%=segments[i].label%>
                                  <%}%>
                        </span>
                      </li>
                      <%}%>
              </ol>
            """
          }
          $legend = $(".protip .#{el} .label-breakdown .legend")
          $legend.html myPieChart.generateLegend()
          legendHolder = $legend[0]


          $legend.find('.pie-legend li').on 'click', (e) ->
            $el = $ e.currentTarget
            label = $el.find('span').text().trim()
            if label is 'no label'
              label = 'no:label'
            else
              label = "label:\"#{label}\""
            $('#js-issues-search').val("#{query_base}:>#{created} #{label} is:issue")
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
          $(".protip .#{el} .label-breakdown .canvas").on 'click', (e) ->
            activePoints = myPieChart.getSegmentsAtEvent(e)
            label = activePoints[0]?.fillColor.split('#').join('')
            $(".protip .#{el} .label-breakdown .val_#{label}").click()

        next(issues_data or {})




  teacup = window.window.teacup
  {span, canvas,  div, ul, ol, li, a, h1, h3, p, iframe, raw, script, coffeescript, link, input, img} = teacup
  old_entry = null
  url = parseQueryString()
  pathname = new URL(window.location.href).pathname

  $('.protip .info').remove()
  $('.protip .info_2').remove()
  $('.protip .info_3').remove()
  $('.protip .history').remove()
  $(".issue-meta .new-comments").remove()
  if /issues$|\/issues\/assigned\/|pulls$|\/pulls\/assigned\/|\/milestones\//.test pathname
    return false unless !!$('#js-issues-search')?.length
    if url.q
      query = decodeURIComponent(url.q)
    else
      query = $('#js-issues-search').val()
    repo = $('.dropdown-header > span').attr('title')

    query = query.replace(/\s/g, '+')

    query_str = "#{query}"
    per_page = 25
    page = url.page or '1'

    injectHistory()
    # canvas test
    if /issues$|\/issues\/assigned\/|\/milestones\//.test pathname
      injectPieChart 'info', true, (issues_data_1 = {}) ->
        injectPieChart 'info_2' , false, (issues_data_2 = {})->
          injectBarGraph 'info_3', {closed: issues_data_1, open: issues_data_2}

    chrome.runtime.sendMessage {
      type: 'search-info'
      query: query_str
      repo:repo
      page: page
      per_page: per_page
      }, (data) ->
        for item in data?.items or []
          if not localStorage[item.html_url]
            markUnread item.number
            continue

          comments = item.comments + 1
          num = parseInt localStorage[item.html_url]

          if num < comments
            markNew(item.number, comments - num)
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
      if localStorage[key] < comment_total
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




