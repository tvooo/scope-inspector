ScopeInspectorView = require './scope-inspector-view'
ScopePathView = require './scope-path-view'
parser = require './parser'

{Range} = require 'atom'

_ = require 'lodash'
Subscriber = require('emissary').Subscriber

plugin = module.exports

Subscriber.extend plugin

lint = ->
  editor = atom.workspace.getActiveEditor();
  editorView = atom.workspaceView.getActiveView();

  if (!editor)
    return

  if (editor.getGrammar().name != 'JavaScript')
    return

  js = editor.getText()

  @scopeTree = parser.getScopeTree( js )

  scopePath = parser.getNestedScopes( @scopeTree.functions[0] )

  @scopeInspectorView ?= new ScopeInspectorView( @scopeTree )
  @scopePathView ?= new ScopePathView( @scopePath )

  @scopeInspectorView?.renderScope( scopePath )
  @scopePathView?.renderScope( scopePath )

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

cursorChanged = ->
  editor = atom.workspace.getActiveEditor();
  if (!editor)
    return

  if (editor.getGrammar().name != 'JavaScript')
    return
  cursor = editor.getCursor()

  scope = getContainingScope( cursor, @scopeTree )
  scopePath = parser.getNestedScopes( scope )

  @scopeInspectorView?.renderScope( scopePath )
  @scopePathView?.renderScope( scopePath )

  console.log "Cursor is in #{scope.name}"

registerEvents = ->
  console.log "Registering ALL the events!"
  atom.workspace.eachEditor (editor) =>
    buffer = editor.getBuffer();
    plugin.subscribe(buffer, 'saved', _.debounce(lint.bind(this), 50));

  atom.workspaceView.eachEditorView (editorView) =>
    plugin.subscribe(editorView, 'cursor:moved', _.debounce(cursorChanged.bind(this), 50));


plugin.scopeInspectorView = null

plugin.activate = (state) ->
  @scopeInspectorView ?= new ScopeInspectorView()
  registerEvents.call(this)

plugin.deactivate = ->
    @scopeInspectorView.destroy()
