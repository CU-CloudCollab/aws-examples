var backup = require('./backup');

exports.handler = function (event, context) {
    backup.backupAll(context);
};
