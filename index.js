// Generated by CoffeeScript 1.8.0
(function() {
  var gh;

  gh = (function() {
    var disableButton, error, fetchUserRepos, getUserInfo, handleError, interactiveSignIn, onUserInfoFetched, onUserReposFetched, populateUserInfo, revokeToken, revoke_button, showButton, signin_button, tokenFetcher, user_info_div, xhrWithAuth;
    error = '';
    xhrWithAuth = function(method, url, interactive, callback) {
      var access_token, getToken, requestComplete, requestStart, retry;
      retry = true;
      access_token = void 0;
      getToken = function() {
        tokenFetcher.getToken(interactive, function(error, token) {
          if (error) {
            callback(error);
            return;
          }
          access_token = token;
          requestStart();
        });
      };
      requestStart = function() {
        var xhr;
        xhr = new XMLHttpRequest;
        xhr.open(method, url);
        xhr.setRequestHeader('Authorization', 'Bearer ' + access_token);
        xhr.onload = requestComplete;
        xhr.send();
      };
      requestComplete = function() {
        if ((this.status < 200 || this.status >= 300) && retry) {
          retry = false;
          tokenFetcher.removeCachedToken(access_token);
          access_token = null;
          getToken();
        } else {
          callback(null, this.status, this.response);
        }
      };
      getToken();
    };
    getUserInfo = function(interactive) {
      xhrWithAuth('GET', 'https://api.github.com/user', interactive, onUserInfoFetched);
    };
    showButton = function(button) {
      if (button != null) {
        button.style.display = 'inline';
      }
      if (button != null) {
        button.disabled = false;
      }
    };
    handleError = function(error) {};
    disableButton = function(button) {
      if (button != null) {
        button.disabled = true;
      }
    };
    onUserInfoFetched = function(error, status, response) {
      var user_info;
      if (!error && status === 200) {
        user_info = JSON.parse(response);
        populateUserInfo(user_info);
        fetchUserRepos(user_info['repos_url']);
      } else {
        handleError(error);
      }
    };
    populateUserInfo = function(user_info) {
      var elem, nameElem;
      elem = user_info_div;
      nameElem = document.createElement('div');
      nameElem.innerHTML = '<b>Hello ' + user_info.name + '</b><br>' + 'Your github page is: ' + user_info.html_url;
      if (elem != null) {
        elem.appendChild(nameElem);
      }
    };
    fetchUserRepos = function(repoUrl) {
      xhrWithAuth('GET', repoUrl, false, onUserReposFetched);
    };
    onUserReposFetched = function(error, status, response) {
      var user_repos;
      if (!error && status === 200) {
        user_repos = JSON.parse(response);
        user_repos.forEach(function(repo) {
          if (repo["private"]) {
            elem.value += '[private repo]';
          } else {
            elem.value += repo.name;
          }
          elem.value += '\n';
        });
      } else {

      }
    };
    interactiveSignIn = function(next) {
      disableButton(signin_button);
      return tokenFetcher.getToken(true, function(error, access_token) {
        return next(error, access_token);
      });
    };
    revokeToken = function() {
      localStorage.removeItem('access_token');
      tokenFetcher.getToken(false, function(error, access_token) {
        return tokenFetcher.removeCachedToken(access_token);
      });
    };
    'use strict';
    signin_button = void 0;
    revoke_button = void 0;
    user_info_div = void 0;
    tokenFetcher = (function() {
      var access_token, clientId, clientSecret, redirectRe, redirectUri;
      clientId = '11442b0924c8d6a98fb7';
      clientSecret = 'a1499b1a5780c8a21ed560b839741e803c4cc936';
      redirectUri = chrome.identity.getRedirectURL('provider_cb');
      redirectRe = new RegExp(redirectUri + '[#?](.*)');
      access_token = null;
      return {
        getToken: function(interactive, callback) {
          var exchangeCodeForToken, handleProviderResponse, options, parseRedirectFragment, setAccessToken;
          parseRedirectFragment = function(fragment) {
            var pairs, values;
            pairs = fragment.split(/&/);
            values = {};
            pairs.forEach(function(pair) {
              var nameval;
              nameval = pair.split(RegExp('='));
              values[nameval[0]] = nameval[1];
            });
            return values;
          };
          handleProviderResponse = function(values) {
            if (values.hasOwnProperty('access_token')) {
              setAccessToken(values.access_token);
            } else if (values.hasOwnProperty('code')) {
              exchangeCodeForToken(values.code);
            } else {
              callback(new Error('Neither access_token nor code avialable.'));
            }
          };
          exchangeCodeForToken = function(code) {
            var xhr;
            xhr = new XMLHttpRequest;
            xhr.open('GET', 'https://github.com/login/oauth/access_token?' + 'client_id=' + clientId + '&client_secret=' + clientSecret + '&redirect_uri=' + redirectUri + '&code=' + code + '&scope=user,repo');
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.setRequestHeader('Accept', 'application/json');
            xhr.onload = function() {
              var response;
              if (this.status === 200) {
                response = JSON.parse(this.responseText);
                if (response.hasOwnProperty('access_token')) {
                  setAccessToken(response.access_token);
                } else {
                  callback(new Error('Cannot obtain access_token from code.'));
                }
              } else {
                callback(new Error('Code exchange failed'));
              }
            };
            xhr.send();
          };
          setAccessToken = function(token) {
            access_token = token;
            localStorage['access_token'] = token;
            callback(null, access_token);
          };
          if (access_token == null) {
            access_token = localStorage['access_token'];
          }
          if (access_token) {
            callback(null, access_token);
            return;
          }
          options = {
            'interactive': interactive,
            'url': 'https://github.com/login/oauth/authorize' + '?client_id=' + clientId + '&redirect_uri=' + encodeURIComponent(redirectUri) + '&scope=user,repo'
          };
          chrome.identity.launchWebAuthFlow(options, function(redirectUri) {
            var matches;
            if (chrome.runtime.lastError) {
              callback(new Error(chrome.runtime.lastError));
              return;
            }
            matches = redirectUri.match(redirectRe);
            if (matches && matches.length > 1) {
              handleProviderResponse(parseRedirectFragment(matches[1]));
            } else {
              callback(new Error('Invalid redirect URI'));
            }
          });
        },
        removeCachedToken: function(token_to_remove) {
          if (access_token === token_to_remove) {
            localStorage.removeItem('access_token');
            access_token = null;
          }
        }
      };
    })();
    return {
      error: error,
      tokenFetcher: tokenFetcher,
      revokeToken: revokeToken,
      xhrWithAuth: xhrWithAuth,
      interactiveSignIn: interactiveSignIn,
      revokeToken: revokeToken,
      getUserInfo: getUserInfo,
      onload: function() {

        /*
        signin_button = document.querySelector('#signin');
        signin_button?.onclick = interactiveSignIn;
        
        revoke_button = document.querySelector('#revoke');
        revoke_button?.onclick = revokeToken;
        
        user_info_div = document.querySelector('#user_info');
        
        
        showButton(signin_button);
        getUserInfo(false);
         */
      }
    };
  })();

  window.gh = gh;

}).call(this);
