{$, View} = require 'atom'

module.exports =
class HighlightView extends View
  constructor: (@editorView, @marker) ->
    super()
    @fadeSpeed = 150
    @fadeFastSpeed = 80

  @content: (editorView) ->
    @div ->

  destroy: ->
    #@remove()
    @detach()

  render: (scope) ->
    @empty().hide()

    startPosition = @editorView.pixelPositionForBufferPosition @marker.getStartPosition()
    endPosition = @editorView.pixelPositionForBufferPosition @marker.getEndPosition()
    lineHeight = @editorView.lineHeight

    if @marker.getRange().isSingleLine()
      background = $('<div class="scope-highlight"/>')
      background.css({top: startPosition.top, left: startPosition.left});
      background.width(endPosition.left - startPosition.left)
      background.height lineHeight
      @append background
    else
      # First line
      background = $('<div class="scope-highlight"/>')
      background.css({top: startPosition.top, left: startPosition.left});
      background.css('right': '0')
      background.height(lineHeight)
      @append background

      # Last line
      background = $('<div class="scope-highlight"/>')
      background.css({top: endPosition.top, left: 0});
      background.width(endPosition.left)
      background.height(lineHeight)
      @append background

      # If it spans more than 2 lines...
      if @marker.getRange().getRows().length > 1
        background = $('<div class="scope-highlight"/>')
        background.css({top: startPosition.top + lineHeight, left: 0});
        background.width('100%')
        background.height(endPosition.top - startPosition.top - lineHeight)
        @append background

    @appendTo @editorView.find('.underlayer')

  showHighlight: ->
    @fadeIn @fadeSpeed
  showHighlightImmediately: ->
    @show()
  hideHighlight: ->
    @fadeOut @fadeSpeed
  hideHighlightImmediately: ->
    @hide()
