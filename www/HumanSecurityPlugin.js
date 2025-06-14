var exec = require('cordova/exec');

var HumanSecurityPlugin = {
  setUserId: function (userId, appId, success, error) {
    exec(success, error, 'HumanSecurityPlugin', 'setUserId', [userId, appId]);
  },

  getHeaders: function (appId, success, error) {
    exec(success, error, 'HumanSecurityPlugin', 'getHeaders', [appId]);
  },

  handleResponse: function (responseString, success, error) {
    exec(success, error, 'HumanSecurityPlugin', 'handleResponse', [responseString]);
  }
};

// Attach to window.plugins if available
if (!window.plugins) {
  window.plugins = {};
}
window.plugins.HumanSecurity = HumanSecurityPlugin;

module.exports = HumanSecurityPlugin;
