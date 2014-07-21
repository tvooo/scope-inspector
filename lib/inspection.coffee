parser = require './parser'
{Range} = require 'atom'
_ = require 'lodash'

isInScope = (cursor, scope) ->
  cursorPos = cursor.getBufferPosition()
  loc = scope.loc
  range = new Range(
    [loc.start.line-1, loc.start.column],
    [loc.end.line-1, loc.end.column]
  )
  return range.containsPoint(cursorPos)

getContainingScope = ( cursor, scope ) =>
  for func in scope.functions
    return getContainingScope(cursor, func) if isInScope( cursor, func)

  return scope

module.exports =
class Inspection
  constructor: (@editorView, @plugin) ->
    @editor = @editorView.getEditor()
    @markers = []
    @registerEvents()
    #@updateMarkers()
    @onSaved()

  destroy: ->
    for marker in @markers
      marker.highlightView.destroy()
      marker.destroy()
    @markers = []
    @editor.inspection = null

  registerEvents: ->
    @editor.buffer.on('saved', _.debounce(@onSaved.bind(this), 50));
    @editorView.on('cursor:moved', _.debounce(@onCursorMoved.bind(this), 50));

  updateMarkers: ->
    for marker in @markers
      marker.highlightView?.destroy()
      marker.destroy()

    @markers = []

    return unless @scopeTree?

    allScopes = @scopeTree.getAllScopes()

    for scope in allScopes
      loc = scope.loc
      range = new Range(
        [loc.start.line-1, loc.start.column],
        [loc.end.line-1, loc.end.column]
      )
      marker = @editor.markBufferRange(range)#.bufferMarker
      marker.scope = scope
      marker.decoration = @editor.decorateMarker(marker, {type: 'highlight', class: 'scope-highlight'})
      console.log marker.decoration

      @markers.push marker

  onCursorMoved: ->
    cursor = @editor.getCursor()
    scope = if @scopeTree? then getContainingScope( cursor, @scopeTree ) else null
    return unless scope != @scope

    @hoistingMarker?.destroy()
    @scope = scope
    scopePath = if @scope? then parser.getNestedScopes( @scope ) else null

    @plugin.scopeInspectorView?.renderScope( scopePath )
    @plugin.scopePathView?.renderScope( scopePath )
    @updateHighlights()

    return unless scopePath?
    hoistedIdentifiers = scope.getHoistedIdentifiers()
    return unless hoistedIdentifiers.length

    range = new Range(
      [scope.hoistingPosition.start.line-1, scope.hoistingPosition.start.column],
      [scope.hoistingPosition.start.line-1, scope.hoistingPosition.start.column + 100]
    )

    @hoistingMarker = marker = @editor.markBufferRange(range).bufferMarker
    @hoistingMarker.decoration = @editor.decorateMarker(marker, {type: 'highlight', class: 'hoisting'})

  focusScope: (scope) ->
    return unless scope != @scope
    @updateHighlightsFast(scope)

  updateHighlights: ->
    for marker in @markers
      if @scope == marker.scope and (marker.scope.parentScope? or atom.config.get 'scope-inspector.highlightGlobalScope')
        marker.decoration.update({type: 'highlight', class: 'scope-highlight active'})
      else
        marker.decoration.update({type: 'highlight', class: 'scope-highlight'})

  updateHighlightsFast: (scope) ->
    #return
    for marker in @markers
      if scope == marker.scope
        marker.decoration.update({type: 'highlight', class: 'scope-highlight active'})
      else
        marker.decoration.update({type: 'highlight', class: 'scope-highlight'}) unless marker.scope == @scope

  onSaved: ->
    # Update scopeTree
    js = @editor.getText()
    try
      @scopeTree = parser.getScopeTree( js )
    catch err
      @scopeTree = null

    @updateMarkers()

    @onCursorMoved()
