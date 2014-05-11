;(function( window, document, $, undefined ) {
  console.log( this );
  $( document ).ready( function() {
    console.log( this );
    $('#btn').on('click', function( event ) {
      console.log( this );
      event.preventDefault();
      $.getJSON('document.json', function( data ) {
        console.log( this );
        data.forEach( function( entry ) {
          console.log( this );
          $('#list').append('<li>' + entry.title + '</li>');
        });
      });
    });
  });
}( window, document, jQuery ));
