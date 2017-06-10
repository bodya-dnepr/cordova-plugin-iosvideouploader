var exec = require('cordova/exec');

exports.getVideo = function(success, error, uri, token) {
  exec(success, error, "iOSVideoUploader", "getVideo", [uri, token]);
};
