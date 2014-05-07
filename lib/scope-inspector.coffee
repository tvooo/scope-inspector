ScopeInspectorView = require './scope-inspector-view'
ScopePathView = require './scope-path-view'
parser = require './parser'

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

  scopeTree = parser.getScopeTree( js )
  scopePath = parser.getNestedScopes( scopeTree.functions[0] )

  @scopeInspectorView ?= new ScopeInspectorView( scopeTree )
  @scopePathView ?= new ScopePathView( scopePath )

  @scopeInspectorView?.renderScope( scopeTree )
  @scopePathView?.renderScope( scopePath )

registerEvents = ->
  console.log "Registering ALL the events!"
  atom.workspace.eachEditor (editor) =>
    buffer = editor.getBuffer();
    events = 'saved';

    plugin.subscribe(buffer, events, _.debounce(lint.bind(this), 50));


plugin.scopeInspectorView = null

plugin.activate = (state) ->
  @scopeInspectorView ?= new ScopeInspectorView()
  registerEvents.call(this)

plugin.deactivate = ->
    @scopeInspectorView.destroy()
