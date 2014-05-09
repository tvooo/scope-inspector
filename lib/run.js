var fs = require('fs'),
    _ = require('lodash')

require('fs').readFile('test.js', function(err, data) {

  syntax = require('./parser').getScopeTree(data.toString());

  printScope( syntax );

  //console.log(JSON.stringify(syntax.node.body[3],null,"  "))

});

function printScope(scope, indent) {
  indent = indent || 0;

  scope.variables.forEach( function( variable ) {
    console.log( (new Array(indent).join(' ')) + variable.name);

  });

  scope.functions.forEach( function( func ) {
    console.log( (new Array(indent).join(' ')) + func.name);
    printScope( func, indent + 4)
  });

}
