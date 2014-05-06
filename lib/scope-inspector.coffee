ScopeInspectorView = require './scope-inspector-view'
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
  console.log parser.getScopes( js )

registerEvents = ->
  console.log "Registering ALL the events!"
  atom.workspace.eachEditor (editor) ->
    buffer = editor.getBuffer();
    events = 'saved';

    plugin.subscribe(buffer, events, _.debounce(lint, 50));


plugin.scopeInspectorView = null

plugin.activate = (state) ->
  @scopeInspectorView = new ScopeInspectorView(state.scopeInspectorViewState)
  registerEvents()

plugin.deactivate = ->
    @scopeInspectorView.destroy()

plugin.serialize = ->
    scopeInspectorViewState: @scopeInspectorView.serialize()
