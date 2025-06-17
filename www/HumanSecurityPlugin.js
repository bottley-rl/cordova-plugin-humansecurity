var exec = require('cordova/exec');

var HumanSecurityPlugin = {
  start: function (success, error) {
    exec(success, error, 'HumanSecurityPlugin', 'start', []);
  },

  setUserId: function (userId, success, error) {
    exec(success, error, 'HumanSecurityPlugin', 'setUserId', [userId]);
  },

  getHeaders: function (success, error) {
    exec(success, error, 'HumanSecurityPlugin', 'getHeaders', []);
  },

  handleResponse: function (responseString, success, error) {
    exec(success, error, 'HumanSecurityPlugin', 'handleResponse', [responseString]);
  }
};

if (!window.plugins) {
  window.plugins = {};
}
window.plugins.HumanSecurity = HumanSecurityPlugin;

module.exports = HumanSecurityPlugin;
