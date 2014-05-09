{$, View} = require 'atom'

module.exports =
class ScopeHighlightView extends View
  constructor: (@editorView, @plugin) ->
    super()
    @fadeSpeed = 150

  @content: (editorView) ->
    @div ->

  destroy: ->
    @detach()

  rerender: (scope) ->
    console.log "Rendering the shit out of this thingie"
    @editorView.find('.underlayer .scope-highlight').fadeOut @fadeSpeed, -> @.remove()

    return unless scope.parentScope? or atom.config.get 'scope-inspector.highlightGlobal'

    backgrounds = []

    startPosition = @editorView.pixelPositionForBufferPosition([scope.loc.start.line-1, scope.loc.start.column])
    endPosition = @editorView.pixelPositionForBufferPosition([scope.loc.end.line-1, scope.loc.end.column])

    if scope.loc.start.line == scope.loc.end.line
      background = $('<div class="scope-highlight"/>')
      background.css({top: startPosition.top, left: startPosition.left});
      background.width(endPosition.left - startPosition.left)
      height = @editorView.lineHeight
      background.height(height)
      background.hide()
      @editorView.find('.underlayer').append(background)
      return

    height = @editorView.lineHeight
    # First line
    background = $('<div class="scope-highlight"/>')
    background.css({top: startPosition.top, left: startPosition.left});
    # Calculating end of line
    line = @editorView.find(".lines .line").eq(scope.loc.start.line-1).find('span.source')
    background.width(line.width() - startPosition.left)
    background.height(height)
    background.hide()
    backgrounds.push background

    # Last line
    background = $('<div class="scope-highlight"/>')
    background.css({top: endPosition.top, left: 0});
    background.width(endPosition.left)
    background.height(height)
    background.hide()
    backgrounds.push background

    # If it spans more than 2 lines...
    if (scope.loc.end.line - scope.loc.start.line) > 1
      background = $('<div class="scope-highlight"/>')
      background.css({top: startPosition.top + height, left: 0});
      background.width('100%')
      background.height(endPosition.top - startPosition.top - height)
      background.hide()
      backgrounds.push background

    for background in backgrounds
      @editorView.find('.underlayer').append(background)
      background.fadeIn(@fadeSpeed)
