HighlightView = require './scope-highlight-view'
HoistingView = require './hoisting-view'
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
    console.log "Initializing Inspection"
    @editor = @editorView.getEditor()
    @markers = []
    @registerEvents()
    @updateMarkers()
    @onSaved()

  registerEvents: ->
    console.log "Registering ALL the events!"
    @editor.buffer.on('saved', _.debounce(@onSaved.bind(this), 50));
    @editorView.on('cursor:moved', _.debounce(@onCursorMoved.bind(this), 50));

  updateMarkers: ->
    for marker in @markers
      marker.highlightView.destroy()
      marker.destroy()

    return unless @scopeTree?

    allScopes = @scopeTree.getAllScopes()
    @markers = []

    for scope in allScopes
      loc = scope.loc
      range = new Range(
        [loc.start.line-1, loc.start.column],
        [loc.end.line-1, loc.end.column]
      )
      marker = @editor.markBufferRange(range).bufferMarker
      marker.scope = scope
      marker.highlightView = new HighlightView(@editorView, marker)
      marker.highlightView.render()
      marker.on 'changed', (event) =>

      @markers.push marker



  onCursorMoved: ->
    cursor = @editor.getCursor()
    scope = getContainingScope( cursor, @scopeTree )
    return unless scope != @scope

    @hoistingView?.destroy()
    @scope = scope
    scopePath = parser.getNestedScopes( @scope )

    @plugin.scopeInspectorView?.renderScope( scopePath )
    @plugin.scopePathView?.renderScope( scopePath )
    @hoistingView = new HoistingView( @ )
    @hoistingView.render( scope )
    @updateHighlights()

    console.log "Cursor is in #{scope.name}"

  focusScope: (scope) ->
    return unless scope != @scope
    @scope = scope
    @updateHighlightsFast()

  updateHighlights: ->
    for marker in @markers
      if @scope == marker.scope and (marker.scope.parentScope? or atom.config.get 'scope-inspector.highlightGlobalScope')
        marker.highlightView.showHighlight()
      else
        marker.highlightView.hideHighlight()

  updateHighlightsFast: ->
    for marker in @markers
      if @scope == marker.scope and (marker.scope.parentScope? or atom.config.get 'scope-inspector.highlightGlobalScope')
        marker.highlightView.showHighlightImmediately()
      else
        marker.highlightView.hideHighlightImmediately()

  onSaved: ->
    # Update scopeTree
    js = @editor.getText()
    @scopeTree = parser.getScopeTree( js )
    @updateMarkers()

    @onCursorMoved()
