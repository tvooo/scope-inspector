require('fs').readFile('test.js', function(err, data) {
  global = require('./parser').getScopeTree(data.toString());
  console.log(global.functions[0].parentScope);
});
