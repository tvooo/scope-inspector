ScopeHighlightView = require './scope-highlight-view'
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
    @scopeHighlightView ?= new ScopeHighlightView(@editorView, @plugin)
    @registerEvents()
    @onSaved()

  registerEvents: ->
    console.log "Registering ALL the events!"
    @editor.buffer.on('saved', _.debounce(@onSaved.bind(this), 50));
    @editorView.on('cursor:moved', _.debounce(@onCursorMoved.bind(this), 50));
    #@editor

    #atom.workspaceView.eachEditorView (editorView) =>
    #  #plugin.subscribe(editorView, 'cursor:moved', _.debounce(cursorChanged.bind(this), 50));

  onCursorMoved: ->
    cursor = @editor.getCursor()
    scope = getContainingScope( cursor, @scopeTree )
    return unless scope != @scope

    @hoistingView?.destroy()
    @scope = scope
    scopePath = parser.getNestedScopes( @scope )

    @plugin.scopeInspectorView?.renderScope( scopePath )
    @plugin.scopePathView?.renderScope( scopePath )
    @scopeHighlightView.render( scope )
    @hoistingView = new HoistingView( @ )
    @hoistingView.render( scope )

    console.log "Cursor is in #{scope.name}"

  onSaved: ->
    # Update scopeTree
    js = @editor.getText()
    @scopeTree = parser.getScopeTree( js )

    @onCursorMoved()
