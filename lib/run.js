require('fs').readFile('test.js', function(err, data) {
  require('./parser').getScopes(data.toString());
});
