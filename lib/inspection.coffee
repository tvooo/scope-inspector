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
  constructor: (@editor, @plugin) ->
    @markers = []
    @onSaved()
    @registerEvents()

  destroy: ->
    for marker in @markers
      marker.highlightView.destroy()
      marker.destroy()
    @markers = []
    @editor.inspection = null

  registerEvents: ->
    @editor.buffer.onDidSave(_.debounce(@onSaved.bind(this), 50))
    @editor.onDidChangeCursorPosition(_.debounce(@onCursorMoved.bind(this), 50))

    atom.config.observe "scope-inspector.highlightCurrentScope", =>
      @updateHighlights()
    atom.config.observe "scope-inspector.showHoistingIndicators", =>
      @updateHoistingIndicators()
    atom.config.observe "scope-inspector.evaluateOnlyOnSave", =>
      @updateEvents()
    atom.config.observe "scope-inspector.evaluationDelay", =>
      @updateEvents()

  updateEvents: ->
    @evaluationSubscription?.dispose()

    delay = atom.config.get "scope-inspector.evaluationDelay"
    if not atom.config.get "scope-inspector.evaluateOnlyOnSave"
      @evaluationSubscription = @editor.buffer.onDidStopChanging(_.debounce(@onSaved.bind(@), delay))

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

      @markers.push marker

  onCursorMoved: ->
    cursor = @editor.getLastCursor()
    scope = if @scopeTree? then getContainingScope( cursor, @scopeTree ) else null
    return unless scope != @scope


    @scope = scope
    scopePath = if @scope? then parser.getNestedScopes( @scope ) else null

    @plugin.scopeInspectorView?.renderScope( scopePath )
    @plugin.scopePathView?.renderScope( scopePath )
    @updateHighlights()

    return unless scopePath?
    @updateHoistingIndicators()

  focusScope: (scope) ->
    return unless scope != @scope or not atom.config.get "scope-inspector.highlightCurrentScope"
    @updateHighlightsFast(scope)

  updateHoistingIndicators: ->
    @hoistingMarker?.destroy()

    scope = @scope
    hoistedIdentifiers = scope.getHoistedIdentifiers()
    return unless hoistedIdentifiers.length

    range = new Range(
      [scope.hoistingPosition.start.line-1, scope.hoistingPosition.start.column],
      [scope.hoistingPosition.start.line-1, scope.hoistingPosition.start.column + 100]
    )

    @hoistingMarker = marker = @editor.markBufferRange(range).bufferMarker
    if atom.config.get "scope-inspector.showHoistingIndicators"
      @hoistingMarker.decoration = @editor.decorateMarker(marker, {type: 'highlight', class: 'hoisting'})

  updateHighlights: ->
    for marker in @markers
      if @scope == marker.scope and (marker.scope.parentScope? or atom.config.get 'scope-inspector.highlightGlobalScope') and atom.config.get "scope-inspector.highlightCurrentScope"
        marker.decoration.setProperties({type: 'highlight', class: 'scope-highlight active'})
      else
        marker.decoration.setProperties({type: 'highlight', class: 'scope-highlight'})

  updateHighlightsFast: (scope) ->
    #return
    for marker in @markers
      if scope == marker.scope
        marker.decoration.setProperties({type: 'highlight', class: 'scope-highlight active'})
      else
        marker.decoration.setProperties({type: 'highlight', class: 'scope-highlight'}) unless marker.scope == @scope and atom.config.get "scope-inspector.highlightCurrentScope"

  onSaved: ->
    # Update scopeTree
    return unless @editor?
    js = @editor.getText()
    try
      @scopeTree = parser.getScopeTree( js )
    catch err
      @scopeTree = null

    @updateMarkers()
    @onCursorMoved()
