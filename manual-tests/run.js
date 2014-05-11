var fs = require('fs'),
    _ = require('lodash')

require('fs').readFile('test.js', function(err, data) {

  syntax = require('./parser').getScopeTree(data.toString());

  //console.log("-----------" + syntax.name, syntax.parentScope);
  //printScope( syntax );
  console.log(syntax.node.body[3].cases);

  //console.log( syntax.node.body[1] )

  //console.log(syntax.getIdentifier('updateStatusbar').getIdentifier('test2').params)
  //console.log(JSON.stringify(syntax.node.body[3],null,"  "))

});

function printScope(scope, indent) {
  indent = indent || 0;

  scope.variables.forEach( function( variable ) {
    console.log( (new Array(indent).join(' ')) + variable.name + (variable.shadowedBy.length ? ' !' : ''));

  });

  scope.functions.forEach( function( func ) {
    console.log( (new Array(indent).join(' ')) + func.name);
    printScope( func, indent + 4)
  });

}
