var server = http.createServer( function( req, res ) {
  parseMarkdown( function( err, data ) {
    compileHtml( data, function( err, data ) {
      res.end( data );
    });
  } );
});

ret[l] = _.sortBy(ret[l], function (el) {
  return el.character;
});

server.listen( 12345 );
