// Generated by CoffeeScript 1.8.0
(function() {
  var executeContent, new_url, old_url;

  old_url = '';

  new_url = '';

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

  executeContent = function() {
    var a, coffeescript, div, h1, h3, iframe, img, inject_key, input, li, link, markNew, markSame, markUnread, ol, old_entry, p, page, parseQueryString, pathname, per_page, query, query_str, raw, repo, script, span, teacup, ul, url, _ref, _ref1;
    console.log('CONTENT EXECUTED');
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
        return $el.find('.issue-title').append("<span class = 'new-comments animated fadeIn' style= 'color:purple;'>\n  " + difference + " new comments\n</span>");
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
        return $el.find('.issue-title').append("<span class = 'new-comments animated fadeIn' style= 'color:green;'>\n  unread ticket\n</span>");
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
        return $el.find('.issue-title').append("<span class = 'new-comments animated fadeIn' style= 'color:orange;'>\n  nothing changed\n</span>");
      });
    };
    teacup = window.window.teacup;
    span = teacup.span, div = teacup.div, ul = teacup.ul, ol = teacup.ol, li = teacup.li, a = teacup.a, h1 = teacup.h1, h3 = teacup.h3, p = teacup.p, iframe = teacup.iframe, raw = teacup.raw, script = teacup.script, coffeescript = teacup.coffeescript, link = teacup.link, input = teacup.input, img = teacup.img;
    old_entry = null;
    url = parseQueryString();
    console.log(localStorage);
    pathname = new URL(window.location.href).pathname;
    if (/issues$|\/issues\/assigned\/|pulls$|\/pulls\/assigned\/|\/milestones\//.test(pathname)) {
      if (!((_ref = $('#js-issues-search')) != null ? _ref.length : void 0)) {
        return false;
      }
      console.log('ISSUES PAGE FOUND');
      query = $('#js-issues-search').val();
      repo = $('head > meta[property="og:title"]').attr('content');
      query = query.replace(/\s/g, '+');
      query_str = "" + query;
      per_page = 25;
      page = url.page || '1';
      console.log(page, 'panda');
      $('.repository-sidebar .history').remove();
      $('.repository-sidebar').append(teacup.render(function() {
        return div('.history animated fadeIn', function() {
          h1('.header', function() {
            return 'History';
          });
          return ol('.his-items', function() {
            var arr, loc, title, _i, _len, _ref1, _results;
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
      chrome.runtime.sendMessage({
        type: 'search-info',
        query: query_str,
        repo: repo,
        page: page,
        per_page: per_page
      }, function(data) {
        var comments, item, num, _i, _len, _ref1, _results;
        console.log(data != null ? data.items : void 0, 'panda');
        _ref1 = (data != null ? data.items : void 0) || [];
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          item = _ref1[_i];
          $("li[data-issue-id='" + item.number + "'] .new-comments").remove();
          if (!localStorage[item.html_url]) {
            console.log('mark_unread', item.number);
            markUnread(item.number);
            continue;
          }
          comments = item.comments + 1;
          num = parseInt(localStorage[item.html_url]);
          if (num < comments) {
            console.log('a');
            _results.push(markNew(item.number, comments - num));
          } else if (num > comments) {
            console.log('b');
            _results.push(localStorage[item.html_url] = comments);
          } else {
            console.log('c');
            _results.push(markSame(item.number));
          }
        }
        return _results;
      });
      return true;
    } else if (/issues\/\d+$|pull\/\d+$/.test(pathname)) {
      if (!((_ref1 = $('.timeline-comment-wrapper > .comment')) != null ? _ref1.length : void 0)) {
        return false;
      }
      console.log('TICKET FOUND', new_url);
      inject_key = (function(_this) {
        return function() {
          var arr, comments, index, item, key, _i, _len, _ref2, _ref3;
          key = new_url;
          if (!/issues\/\d+$|pull\/\d+$/.test(key)) {
            return;
          }
          comments = (_ref2 = $('.timeline-comment-wrapper > .comment')) != null ? _ref2.length : void 0;
          console.log(key, comments, 'SET');
          localStorage[key] = comments;
          if (!((_ref3 = localStorage['history']) != null ? _ref3.length : void 0)) {
            localStorage['history'] = JSON.stringify({});
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
      inject_key();
      window.addEventListener("beforeunload", function(e) {
        return inject_key();
      });
      return true;
    } else {
      return true;
    }
  };

}).call(this);
