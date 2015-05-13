// Generated by CoffeeScript 1.8.0
(function() {
  var comment_listener, executeContent, getDate, hexToRgb, new_url, old_url;

  old_url = '';

  new_url = '';

  comment_listener = null;

  if (window.urlWatchInterval) {
    clearInterval(window.urlWatchInterval);
  }

  window.urlWatchInterval = setInterval((function() {
    return chrome.runtime.sendMessage({
      type: 'get-config',
      config: 'disable'
    }, function(data) {
      if (data === 'true') {
        return;
      }
      new_url = window.location.href;
      if (old_url !== new_url) {
        if (executeContent()) {
          return old_url = new_url;
        }
      }
    });
  }), 1000);

  getDate = function(date) {
    var breakdown;
    breakdown = date.match(/(\d+)/g);
    return new Date(breakdown[0], parseInt(breakdown[1]) - 1, breakdown[2]);
  };

  hexToRgb = function(hex) {
    var result;
    result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (result) {
      return {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
      };
    } else {
      return null;
    }
  };

  executeContent = function() {
    var a, canvas, coffeescript, comment_total, div, h1, h3, iframe, img, injectBarGraph, injectHistory, injectPieChart, inject_key, input, li, link, markNew, markSame, markUnread, ol, old_entry, p, page, parseQueryString, pathname, per_page, query, query_str, raw, repo, script, span, teacup, ul, url, _ref, _ref1, _ref2;
    if (comment_listener) {
      clearInterval(comment_listener);
    }
    if (!((_ref = localStorage['history']) != null ? _ref.length : void 0)) {
      localStorage['history'] = JSON.stringify([]);
    }
    parseQueryString = function() {
      var objURL, str;
      str = window.location.search;
      objURL = {};
      str.replace(new RegExp('([^?=&]+)(=([^&]*))?', 'g'), function($0, $1, $2, $3) {
        objURL[$1] = $3;
      });
      return objURL;
    };
    markNew = function(ticket, difference) {
      return chrome.runtime.sendMessage({
        type: 'get-config',
        config: 'new'
      }, function(data) {
        var $el;
        if (data !== 'true') {
          return;
        }
        $el = $("li[data-issue-id='" + ticket + "']");
        return $el.find('.issue-title .issue-meta').append("<span class = 'new-comments animated fadeIn' style= 'color:purple;'>\n  " + difference + " new comments\n</span>");
      });
    };
    markUnread = function(ticket) {
      return chrome.runtime.sendMessage({
        type: 'get-config',
        config: 'unread'
      }, function(data) {
        var $el;
        if (data !== 'true') {
          return;
        }
        $el = $("li[data-issue-id='" + ticket + "']");
        return $el.find('.issue-title .issue-meta').append("<span class = 'new-comments animated fadeIn' style= 'color:green;'>\n  unread ticket\n</span>");
      });
    };
    markSame = function(ticket) {
      return chrome.runtime.sendMessage({
        type: 'get-config',
        config: 'nochange'
      }, function(data) {
        var $el;
        if (data !== 'true') {
          return;
        }
        $el = $("li[data-issue-id='" + ticket + "']");
        return $el.find('.issue-title .issue-meta').append("<span class = 'new-comments animated fadeIn' style= 'color:orange;'>\n  nothing changed\n</span>");
      });
    };
    injectHistory = function() {
      return chrome.runtime.sendMessage({
        type: 'get-config',
        config: 'user_history'
      }, function(data) {
        if (data !== 'true') {
          return;
        }
        return $('.repository-sidebar').append(teacup.render(function() {
          return div('.history animated fadeIn', function() {
            h1('.header', function() {
              return "Issue History for You";
            });
            return ol('.his-items', function() {
              var arr, loc, title, url, _i, _len, _ref1, _results;
              arr = JSON.parse(localStorage['history']).reverse();
              _ref1 = arr || [];
              _results = [];
              for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
                loc = _ref1[_i];
                title = loc.title, url = loc.url;
                _results.push(li('.hist-item', function() {
                  return a({
                    href: url
                  }, function() {
                    return title;
                  });
                }));
              }
              return _results;
            });
          });
        }));
      });
    };
    injectBarGraph = function(el, data) {
      return chrome.runtime.sendMessage({
        type: 'get-config',
        config: ["user_total_open", "user_total_closed", "weekly_total"]
      }, (function(_this) {
        return function(data_configs) {
          if (!Object.keys(data_configs).length) {
            return;
          }
          $('.protip').append(teacup.render(function() {
            return div("." + el, function() {
              h1("Weekly Breakdown");
              div('.total-issues', function() {
                h1('.header', function() {
                  return "Total Issues Closed/Opened";
                });
                canvas('.canvas', {
                  'width': '920',
                  'height': '180'
                });
                return div('.legend');
              });
              div('.user-closed', function() {
                h1('.header', function() {
                  return "User Issues Closed";
                });
                canvas('.canvas', {
                  'width': '920',
                  'height': '180'
                });
                return div('.legend');
              });
              return div('.user-opened', function() {
                h1('.header', function() {
                  return "User Issues Opened";
                });
                canvas('.canvas', {
                  'width': '920',
                  'height': '180'
                });
                return div('.legend');
              });
            });
          }));
          (function() {
            var $legend, chart_data, closed, color, color_2, ctx, date, day, item, myPieChart, open, _i, _j, _len, _len1, _ref1, _ref2;
            if ((data_configs != null ? data_configs.weekly_total : void 0) !== 'true') {
              $(".protip ." + el + " .total-issues").remove();
              return;
            }
            ctx = $(".protip ." + el + " .total-issues .canvas").get(0).getContext('2d');
            closed = data.closed, open = data.open;
            color = hexToRgb(window.colors[0]);
            color_2 = hexToRgb(window.colors[1]);
            chart_data = {
              labels: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
              datasets: [
                {
                  label: "Issues Opened",
                  fillColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",0.2)",
                  strokeColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",1)",
                  pointColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",1)",
                  pointStrokeColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",1)",
                  data: [0, 0, 0, 0, 0, 0, 0]
                }, {
                  label: "Issues Closed",
                  fillColor: "rgba(" + color_2.r + "," + color_2.g + "," + color_2.b + ",0.2)",
                  strokeColor: "rgba(" + color_2.r + "," + color_2.g + "," + color_2.b + ",1)",
                  pointColor: "rgba(" + color_2.r + "," + color_2.g + "," + color_2.b + ",1)",
                  pointStrokeColor: "rgba(" + color_2.r + "," + color_2.g + "," + color_2.b + ",1)",
                  data: [0, 0, 0, 0, 0, 0, 0]
                }
              ]
            };
            _ref1 = (open != null ? open.items : void 0) || [];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              item = _ref1[_i];
              date = getDate(item.created_at);
              day = date.getDay();
              chart_data.datasets[0].data[day]++;
            }
            _ref2 = (closed != null ? closed.items : void 0) || [];
            for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
              item = _ref2[_j];
              date = getDate(item.closed_at);
              day = date.getDay();
              chart_data.datasets[1].data[day]++;
            }
            myPieChart = new Chart(ctx).BarOneTip(chart_data, {
              tooltipTemplate: "<%if (datasetLabel){%><%=datasetLabel%>: <%}%><%= value %>",
              legendTemplate: "<ul class=\ \"<%=name.toLowerCase()%>-legend\">\n  <% for (var i=0; i<datasets.length; i++){%>\n    <div style=\ \"background-color:<%=datasets[i].fillColor%>;border: 1px solid <%=datasets[i].strokeColor%>;padding:1px;\">\n      <%if(datasets[i].label){%>\n          <%=datasets[i].label%>\n      <%}%>\n    </div>\n  <%}%>\n</ul>"
            });
            $legend = $(".protip ." + el + " .total-issues .legend");
            $legend.html(myPieChart.generateLegend());
            return $(".protip ." + el + " .total-issues .canvas").click(function(e) {
              var activeBars, assignee, bar, created, currentBar, current_label, dayCount, eventData, labels, query, t, _k, _len2;
              activeBars = myPieChart.getBarsAtEvent(e);
              eventData = Chart.helpers.getRelativePosition(e);
              currentBar = null;
              for (_k = 0, _len2 = activeBars.length; _k < _len2; _k++) {
                bar = activeBars[_k];
                if (bar.inRange(eventData.x, eventData.y)) {
                  currentBar = bar;
                }
              }
              if (!currentBar) {
                return;
              }
              current_label = currentBar.label;
              labels = myPieChart.scale.xLabels;
              t = new Date();
              dayCount = labels.indexOf(current_label);
              t.setDate(t.getDate() - (t.getDay() - dayCount));
              t.setHours(0, 0, 0, 0);
              created = t.toISOString().substr(0, 10);
              assignee = currentBar.datasetLabel;
              if (assignee === 'Issues Opened') {
                query = "created:" + created;
              } else {
                query = "closed:" + created;
              }
              $('#js-issues-search').val("" + query + " is:issue");
              $('#js-issues-search').closest('form').submit();
            });
          })();
          (function() {
            var $legend, chart_data, closed, color, color_index, ctx, date, day, item, myPieChart, user, _i, _len, _ref1, _ref2;
            if ((data_configs != null ? data_configs.user_total_closed : void 0) !== 'true') {
              $(".protip ." + el + " .user-closed").remove();
              return;
            }
            ctx = $(".protip ." + el + " .user-closed .canvas").get(0).getContext('2d');
            closed = data.closed;
            chart_data = {
              labels: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
              datasets: {}
            };
            color_index = 0;
            _ref1 = (closed != null ? closed.items : void 0) || [];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              item = _ref1[_i];
              date = getDate(item.closed_at);
              day = date.getDay();
              user = ((_ref2 = item.assignee) != null ? _ref2.login : void 0) || 'unassigned';
              if (!chart_data.datasets[user]) {
                color = hexToRgb(window.colors[color_index]);
                chart_data.datasets[user] = {
                  label: "" + user,
                  fillColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",0.2)",
                  strokeColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",1)",
                  pointColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",1)",
                  pointStrokeColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",1)",
                  pointHighlightFill: "#fff",
                  pointHighlightStroke: "rgba(151,187,205,1)",
                  data: [0, 0, 0, 0, 0, 0, 0]
                };
                color_index++;
              }
              chart_data.datasets[user].data[day]++;
            }
            myPieChart = new Chart(ctx).BarOneTip(chart_data, {
              tooltipTemplate: "<%if (datasetLabel){%><%=datasetLabel%>: <%}%><%= value %>",
              pointDot: false,
              legendTemplate: "<div class=\ \"<%=name.toLowerCase()%>-legend\">\n  <% for (var i=0; i<datasets.length; i++){%>\n      <div style=\ \"background-color:<%=datasets[i].fillColor%>;border: 1px solid <%=datasets[i].strokeColor%>;padding:1px;\">\n        <%if(datasets[i].label){%>\n            <%=datasets[i].label%>\n        <%}%>\n      </div>\n  <%}%>\n</div>"
            });
            $legend = $(".protip ." + el + " .user-closed .legend");
            $legend.html(myPieChart.generateLegend());
            return $(".protip ." + el + " .user-closed .canvas").click(function(e) {
              var activeBars, assignee, bar, created, currentBar, current_label, dayCount, eventData, labels, t, _j, _len1;
              activeBars = myPieChart.getBarsAtEvent(e);
              eventData = Chart.helpers.getRelativePosition(e);
              currentBar = null;
              for (_j = 0, _len1 = activeBars.length; _j < _len1; _j++) {
                bar = activeBars[_j];
                if (bar.inRange(eventData.x, eventData.y)) {
                  currentBar = bar;
                }
              }
              if (!currentBar) {
                return;
              }
              current_label = currentBar.label;
              labels = myPieChart.scale.xLabels;
              t = new Date();
              dayCount = labels.indexOf(current_label);
              t.setDate(t.getDate() - (t.getDay() - dayCount));
              t.setHours(0, 0, 0, 0);
              created = t.toISOString().substr(0, 10);
              assignee = currentBar.datasetLabel;
              if (assignee === 'unassigned') {
                assignee = 'no:assignee';
              } else {
                assignee = "assignee:" + assignee;
              }
              $('#js-issues-search').val("closed:" + created + " " + assignee + " is:issue");
              $('#js-issues-search').closest('form').submit();
            });
          })();
          return (function() {
            var $legend, chart_data, color, color_index, ctx, date, day, item, myPieChart, open, user, _i, _len, _ref1, _ref2;
            if ((data_configs != null ? data_configs.user_total_open : void 0) !== 'true') {
              $(".protip ." + el + " .user-opened").remove();
              return;
            }
            ctx = $(".protip ." + el + " .user-opened .canvas").get(0).getContext('2d');
            open = data.open;
            chart_data = {
              labels: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
              datasets: {}
            };
            color_index = 0;
            _ref1 = (open != null ? open.items : void 0) || [];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              item = _ref1[_i];
              date = getDate(item.created_at);
              day = date.getDay();
              user = ((_ref2 = item.assignee) != null ? _ref2.login : void 0) || 'unassigned';
              if (!chart_data.datasets[user]) {
                color = hexToRgb(window.colors[color_index]);
                chart_data.datasets[user] = {
                  label: "" + user,
                  fillColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",0.2)",
                  strokeColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",1)",
                  pointColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",1)",
                  pointStrokeColor: "rgba(" + color.r + "," + color.g + "," + color.b + ",1)",
                  pointHighlightFill: "#fff",
                  pointHighlightStroke: "rgba(151,187,205,1)",
                  data: [0, 0, 0, 0, 0, 0, 0]
                };
                color_index++;
              }
              chart_data.datasets[user].data[day]++;
            }
            myPieChart = new Chart(ctx).BarOneTip(chart_data, {
              tooltipTemplate: "<%if (datasetLabel){%><%=datasetLabel%>: <%}%><%= value %>",
              legendTemplate: "<div class=\ \"<%=name.toLowerCase()%>-legend\">\n  <% for (var i=0; i<datasets.length; i++){%>\n      <div style=\ \"background-color:<%=datasets[i].fillColor%>;border: 1px solid <%=datasets[i].strokeColor%>;padding:1px;\">\n        <%if(datasets[i].label){%>\n            <%=datasets[i].label%>\n        <%}%>\n      </div>\n  <%}%>\n</div>"
            });
            $legend = $(".protip ." + el + " .user-opened .legend");
            $legend.html(myPieChart.generateLegend());
            return $(".protip ." + el + " .user-opened .canvas").click(function(e) {
              var activeBars, assignee, bar, created, currentBar, current_label, dayCount, eventData, labels, t, _j, _len1;
              console.log('HIT');
              activeBars = myPieChart.getBarsAtEvent(e);
              eventData = Chart.helpers.getRelativePosition(e);
              currentBar = null;
              for (_j = 0, _len1 = activeBars.length; _j < _len1; _j++) {
                bar = activeBars[_j];
                if (bar.inRange(eventData.x, eventData.y)) {
                  currentBar = bar;
                }
              }
              if (!currentBar) {
                return;
              }
              current_label = currentBar.label;
              labels = myPieChart.scale.xLabels;
              t = new Date();
              dayCount = labels.indexOf(current_label);
              t.setDate(t.getDate() - (t.getDay() - dayCount));
              t.setHours(0, 0, 0, 0);
              created = t.toISOString().substr(0, 10);
              assignee = currentBar.datasetLabel;
              if (assignee === 'unassigned') {
                assignee = 'no:assignee';
              } else {
                assignee = "assignee:" + assignee;
              }
              console.log("created:" + created);
              $('#js-issues-search').val("created:" + created + " " + assignee + " is:issue");
              $('#js-issues-search').closest('form').submit();
            });
          })();
        };
      })(this));
    };
    injectPieChart = function(el, closed, next) {
      var query_base;
      if (closed) {
        query_base = "closed";
      } else {
        query_base = "created";
      }
      return chrome.runtime.sendMessage({
        type: 'get-config',
        config: ["user_breakdown_" + query_base, "milestone_breakdown_" + query_base, "label_breakdown_" + query_base]
      }, (function(_this) {
        return function(data_configs) {
          var created, dayCount, query_issues, t;
          $(".protip > ." + el).remove();
          if (!Object.keys(data_configs).length) {
            return;
          }
          t = new Date();
          dayCount = t.getDay();
          t.setDate(t.getDate() - dayCount);
          t.setHours(0, 0, 0, 0);
          created = t.toISOString().substr(0, 10);
          query_issues = "" + query_base + ":>" + created + " is:issue";
          return chrome.runtime.sendMessage({
            type: 'search-info',
            query: query_issues,
            repo: repo,
            page: 1,
            per_page: 1000
          }, function(issues_data) {
            var ctx, _ref1;
            if (!(issues_data != null ? (_ref1 = issues_data.items) != null ? _ref1.length : void 0 : void 0)) {
              return next({});
            }
            $('.protip').append(teacup.render(function() {
              return div("." + el, function() {
                var _ref2;
                h1("" + (issues_data != null ? (_ref2 = issues_data.items) != null ? _ref2.length : void 0 : void 0) + " Issues " + (query_base.toUpperCase()) + " this week for " + repo);
                div('.issues-closed animated fadeIn', function() {
                  h1('.header', function() {
                    return "User Breakdown";
                  });
                  canvas('.canvas', {
                    'width': '180',
                    'height': '180'
                  });
                  return div('.legend', function() {
                    return 'loading...';
                  });
                });
                div('.milestone-breakdown animated fadeIn', function() {
                  h1('.header', function() {
                    return "Milestone Breakdown";
                  });
                  canvas('.canvas', {
                    'width': '180',
                    'height': '180'
                  });
                  return div('.legend', function() {
                    return 'loading...';
                  });
                });
                return div('.label-breakdown animated fadeIn', function() {
                  h1('.header', function() {
                    return "Label Breakdown";
                  });
                  canvas('.canvas', {
                    'width': '180',
                    'height': '180'
                  });
                  return div('.legend', function() {
                    return 'loading...';
                  });
                });
              });
            }));
            ctx = $(".protip ." + el + " .issues-closed .canvas").get(0).getContext('2d');

            /* breakup issues by user */
            (function() {
              var $legend, config_data, config_index, helpers, item, legendHolder, myPieChart, user_data, user_index, _i, _len, _ref2;
              if (data_configs["user_breakdown_" + query_base] !== 'true') {
                $("." + el + " > .issues-closed").remove();
                return;
              }
              user_data = [];
              config_data = {};
              config_index = -1;
              _ref2 = issues_data != null ? issues_data.items : void 0;
              for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                item = _ref2[_i];
                if (item.assignee == null) {
                  item.assignee = {
                    login: 'unassigned'
                  };
                }
                if (config_data[item.assignee.login] === void 0) {
                  config_index++;
                  config_data[item.assignee.login] = config_index;
                }
                user_index = config_data[item.assignee.login];
                if (user_data[user_index] == null) {
                  user_data[user_index] = {
                    value: 0,
                    color: window.colors[user_index],
                    highlight: window.colors[user_index],
                    label: item.assignee.login
                  };
                }
                user_data[user_index].value++;
              }
              user_data.sort(function(a, b) {
                return b.value - a.value;
              });
              myPieChart = new Chart(ctx).Pie(user_data, {
                legendTemplate: "<ol class=\ \"<%=name.toLowerCase()%>-legend\">\n    <% for (var i=0; i<segments.length; i++){%>\n        <li class=\ \"val_<%=segments[i].fillColor.split('#').join('')%>\" style=\ \"color:<%=segments[i].fillColor%>\" >\n          <span>\n            <%if(segments[i].label){%>\n                <%=segments[i].label%>\n                    <%}%>\n          </span>\n        </li>\n        <%}%>\n</ol>"
              });
              $legend = $(".protip ." + el + " .issues-closed .legend");
              $legend.html(myPieChart.generateLegend());
              legendHolder = $legend[0];
              $legend.find('.pie-legend li').on('click', function(e) {
                var $el, assignee;
                console.log('INSIDE');
                $el = $(e.currentTarget);
                assignee = $el.find('span').text().trim();
                if (assignee === 'unassigned') {
                  assignee = 'no:assignee';
                } else {
                  assignee = "assignee:" + assignee;
                }
                $('#js-issues-search').val("" + query_base + ":>" + created + " " + assignee + " is:issue");
                return $('#js-issues-search').closest('form').submit();
              });
              helpers = Chart.helpers;
              helpers.each($legend.find('.pie-legend').children(), function(legendNode, index) {
                helpers.addEvent(legendNode, 'mouseover', function() {
                  var activeSegment;
                  activeSegment = myPieChart.segments[index];
                  activeSegment.save();
                  myPieChart.showTooltip([activeSegment]);
                  activeSegment.restore();
                });
              });
              helpers.addEvent($legend[0], 'mouseleave', function() {
                myPieChart.draw();
              });
              return $(".protip ." + el + " .issues-closed .canvas").on('click', function(e) {
                var activePoints, label, _ref3;
                activePoints = myPieChart.getSegmentsAtEvent(e);
                label = (_ref3 = activePoints[0]) != null ? _ref3.fillColor.split('#').join('') : void 0;
                return $(".protip ." + el + " .issues-closed .val_" + label).click();
              });
            })();

            /* breakup issues by Milestone */
            (function() {
              var $legend, config_data, config_index, helpers, item, legendHolder, milestone_data, milestone_index, myPieChart, _i, _len, _ref2;
              if (data_configs["milestone_breakdown_" + query_base] !== 'true') {
                $("." + el + " > .milestone-breakdown").remove();
                return;
              }
              ctx = $(".protip ." + el + " .milestone-breakdown .canvas").get(0).getContext('2d');
              milestone_data = [];
              config_data = {};
              config_index = -1;
              _ref2 = issues_data != null ? issues_data.items : void 0;
              for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                item = _ref2[_i];
                if (item.milestone == null) {
                  item.milestone = {
                    title: 'no milestone'
                  };
                }
                if (config_data[item.milestone.title] === void 0) {
                  config_index++;
                  config_data[item.milestone.title] = config_index;
                }
                milestone_index = config_data[item.milestone.title];
                if (milestone_data[milestone_index] == null) {
                  milestone_data[milestone_index] = {
                    value: 0,
                    color: window.colors[milestone_index],
                    highlight: window.colors[milestone_index],
                    label: item.milestone.title
                  };
                }
                milestone_data[milestone_index].value++;
              }
              milestone_data.sort(function(a, b) {
                return b.value - a.value;
              });
              myPieChart = new Chart(ctx).Pie(milestone_data, {
                legendTemplate: "<ol class=\ \"<%=name.toLowerCase()%>-legend\">\n    <% for (var i=0; i<segments.length; i++){%>\n        <li class=\ \"val_<%=segments[i].fillColor.split('#').join('')%>\" style=\ \"color:<%=segments[i].fillColor%>\" >\n          <span>\n            <%if(segments[i].label){%>\n                <%=segments[i].label%>\n                    <%}%>\n          </span>\n        </li>\n        <%}%>\n</ol>"
              });
              $legend = $(".protip ." + el + " .milestone-breakdown .legend");
              $legend.html(myPieChart.generateLegend());
              legendHolder = $legend[0];
              $legend.find('.pie-legend li').on('click', function(e) {
                var $el, milestone;
                $el = $(e.currentTarget);
                milestone = $el.find('span').text().trim();
                if (milestone === 'no milestone') {
                  milestone = 'no:milestone';
                } else {
                  milestone = "milestone:\"" + milestone + "\"";
                }
                $('#js-issues-search').val("" + query_base + ":>" + created + " " + milestone + " is:issue");
                return $('#js-issues-search').closest('form').submit();
              });
              helpers = Chart.helpers;
              helpers.each($legend.find('.pie-legend').children(), function(legendNode, index) {
                helpers.addEvent(legendNode, 'mouseover', function() {
                  var activeSegment;
                  activeSegment = myPieChart.segments[index];
                  activeSegment.save();
                  myPieChart.showTooltip([activeSegment]);
                  activeSegment.restore();
                });
              });
              helpers.addEvent($legend[0], 'mouseleave', function() {
                myPieChart.draw();
              });
              return $(".protip ." + el + " .milestone-breakdown .canvas").on('click', function(e) {
                var activePoints, label, _ref3;
                activePoints = myPieChart.getSegmentsAtEvent(e);
                label = (_ref3 = activePoints[0]) != null ? _ref3.fillColor.split('#').join('') : void 0;
                return $(".protip ." + el + " .milestone-breakdown .val_" + label).click();
              });
            })();

            /* breakup issues by Label */
            (function() {
              var $legend, config_data, config_index, helpers, item, label, label_index, legendHolder, milestone_data, myPieChart, _i, _j, _len, _len1, _ref2, _ref3, _ref4;
              if (data_configs["label_breakdown_" + query_base] !== 'true') {
                $("." + el + " > .label-breakdown").remove();
                return;
              }
              ctx = $(".protip ." + el + " .label-breakdown .canvas").get(0).getContext('2d');
              milestone_data = [];
              config_data = {};
              config_index = -1;
              console.log(issues_data, 'sdaadasasd');
              _ref2 = issues_data != null ? issues_data.items : void 0;
              for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                item = _ref2[_i];
                if (!((_ref3 = item.labels) != null ? _ref3.length : void 0)) {
                  item.labels = [
                    {
                      name: 'no label',
                      color: '000000'
                    }
                  ];
                }
                _ref4 = item.labels;
                for (_j = 0, _len1 = _ref4.length; _j < _len1; _j++) {
                  label = _ref4[_j];
                  if (config_data[label.name] === void 0) {
                    config_index++;
                    config_data[label.name] = config_index;
                  }
                  label_index = config_data[label.name];
                  if (milestone_data[label_index] == null) {
                    milestone_data[label_index] = {
                      value: 0,
                      color: window.colors[label_index],
                      highlight: window.colors[label_index],
                      label: label.name
                    };
                  }
                  milestone_data[label_index].value++;
                }
              }
              milestone_data.sort(function(a, b) {
                return b.value - a.value;
              });
              myPieChart = new Chart(ctx).Pie(milestone_data, {
                legendTemplate: "<ol class=\ \"<%=name.toLowerCase()%>-legend\">\n    <% for (var i=0; i<segments.length; i++){%>\n        <li class=\ \"val_<%=segments[i].fillColor.split('#').join('')%>\" style=\ \"color:<%=segments[i].fillColor%>\" >\n          <span>\n            <%if(segments[i].label){%>\n                <%=segments[i].label%>\n                    <%}%>\n          </span>\n        </li>\n        <%}%>\n</ol>"
              });
              $legend = $(".protip ." + el + " .label-breakdown .legend");
              $legend.html(myPieChart.generateLegend());
              legendHolder = $legend[0];
              $legend.find('.pie-legend li').on('click', function(e) {
                var $el;
                $el = $(e.currentTarget);
                label = $el.find('span').text().trim();
                if (label === 'no label') {
                  label = 'no:label';
                } else {
                  label = "label:\"" + label + "\"";
                }
                $('#js-issues-search').val("" + query_base + ":>" + created + " " + label + " is:issue");
                return $('#js-issues-search').closest('form').submit();
              });
              helpers = Chart.helpers;
              helpers.each($legend.find('.pie-legend').children(), function(legendNode, index) {
                helpers.addEvent(legendNode, 'mouseover', function() {
                  var activeSegment;
                  activeSegment = myPieChart.segments[index];
                  activeSegment.save();
                  myPieChart.showTooltip([activeSegment]);
                  activeSegment.restore();
                });
              });
              helpers.addEvent($legend[0], 'mouseleave', function() {
                myPieChart.draw();
              });
              return $(".protip ." + el + " .label-breakdown .canvas").on('click', function(e) {
                var activePoints, _ref5;
                activePoints = myPieChart.getSegmentsAtEvent(e);
                console.log(activePoints, '123');
                label = (_ref5 = activePoints[0]) != null ? _ref5.fillColor.split('#').join('') : void 0;
                return $(".protip ." + el + " .label-breakdown .val_" + label).click();
              });
            })();
            return next(issues_data || {});
          });
        };
      })(this));
    };
    teacup = window.window.teacup;
    span = teacup.span, canvas = teacup.canvas, div = teacup.div, ul = teacup.ul, ol = teacup.ol, li = teacup.li, a = teacup.a, h1 = teacup.h1, h3 = teacup.h3, p = teacup.p, iframe = teacup.iframe, raw = teacup.raw, script = teacup.script, coffeescript = teacup.coffeescript, link = teacup.link, input = teacup.input, img = teacup.img;
    old_entry = null;
    url = parseQueryString();
    pathname = new URL(window.location.href).pathname;
    $('.protip .info').remove();
    $('.protip .info_2').remove();
    $('.protip .info_3').remove();
    $('.repository-sidebar .history').remove();
    $(".issue-meta .new-comments").remove();
    if (/issues$|\/issues\/assigned\/|pulls$|\/pulls\/assigned\/|\/milestones\//.test(pathname)) {
      if (!((_ref1 = $('#js-issues-search')) != null ? _ref1.length : void 0)) {
        return false;
      }
      if (url.q) {
        query = decodeURIComponent(url.q);
      } else {
        query = $('#js-issues-search').val();
      }
      repo = $('.dropdown-header > span').attr('title');
      query = query.replace(/\s/g, '+');
      query_str = "" + query;
      per_page = 25;
      page = url.page || '1';
      injectHistory();
      if (/issues$|\/issues\/assigned\/|\/milestones\//.test(pathname)) {
        injectPieChart('info', true, function(issues_data_1) {
          if (issues_data_1 == null) {
            issues_data_1 = {};
          }
          return injectPieChart('info_2', false, function(issues_data_2) {
            if (issues_data_2 == null) {
              issues_data_2 = {};
            }
            return injectBarGraph('info_3', {
              closed: issues_data_1,
              open: issues_data_2
            });
          });
        });
      }
      chrome.runtime.sendMessage({
        type: 'search-info',
        query: query_str,
        repo: repo,
        page: page,
        per_page: per_page
      }, function(data) {
        var comments, item, num, _i, _len, _ref2, _results;
        _ref2 = (data != null ? data.items : void 0) || [];
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          item = _ref2[_i];
          if (!localStorage[item.html_url]) {
            markUnread(item.number);
            continue;
          }
          comments = item.comments + 1;
          num = parseInt(localStorage[item.html_url]);
          if (num < comments) {
            _results.push(markNew(item.number, comments - num));
          } else {
            _results.push(markSame(item.number));
          }
        }
        return _results;
      });
      return true;
    } else if (/issues\/\d+$|pull\/\d+$/.test(pathname)) {
      if (!((_ref2 = $('.timeline-comment-wrapper > .comment')) != null ? _ref2.length : void 0)) {
        return false;
      }
      comment_total = 0;
      inject_key = (function(_this) {
        return function() {
          var arr, index, item, key, _i, _len;
          key = new_url;
          if (!/issues\/\d+$|pull\/\d+$/.test(key)) {
            return;
          }
          if (localStorage[key] < comment_total) {
            localStorage[key] = comment_total;
          }
          arr = JSON.parse(localStorage['history']);
          for (index = _i = 0, _len = arr.length; _i < _len; index = ++_i) {
            item = arr[index];
            if (item.url === key) {
              arr.splice(index, 1);
              break;
            }
          }
          arr.push({
            title: $('.js-issue-title').text(),
            url: key
          });
          arr = arr.slice(-5);
          return localStorage['history'] = JSON.stringify(arr);
        };
      })(this);
      comment_listener = setInterval((function() {
        var new_comments, _ref3;
        new_comments = (_ref3 = $('.timeline-comment-wrapper > .comment')) != null ? _ref3.length : void 0;
        if (new_comments && new_comments !== comment_total) {
          comment_total = new_comments;
          return inject_key();
        }
      }), 100);
      return true;
    } else {
      return true;
    }
  };

}).call(this);
