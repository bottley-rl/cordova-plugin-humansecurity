var exec = require('cordova/exec');

var HumanSecurityPlugin = {
  start: function (appId, domains, success, error) {
    exec(success, error, 'HumanSecurityPlugin', 'start', [appId, domains]);
  },

  setUserId: function (userId, appId, success, error) {
    exec(success, error, 'HumanSecurityPlugin', 'setUserId', [userId, appId]);
  }
};

// Attach to window.plugins if available
if (!window.plugins) {
  window.plugins = {};
}
window.plugins.HumanSecurity = HumanSecurityPlugin;

module.exports = HumanSecurityPlugin;
