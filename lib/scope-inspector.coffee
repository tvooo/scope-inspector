_ = require 'lodash'
Subscriber = require('emissary').Subscriber
Inspection = require './inspection'
ScopeInspectorView = require './scope-inspector-view'
ScopePathView = require './scope-path-view'
plugin = module.exports

Subscriber.extend plugin

# Strategy
#
# - Attach one Inspection instance to each .js editor, saving the state, parse tree and managing views and events
# - one InspectorView and one PathView in total
# - For each scope, a marker is set from beginning to end of scope
# - For each marker, a view is created, but not rendered
# - This view renders if scope is in focus. if there are no child scopes, it's easy, otherwise it's more tricky. but manage it via markers!
# - Inspection events
#   * buffer-changed: update parse tree; new parse tree fires event to update views
#   * cursor-changed: check if scope changed; if yes, update scope path, fire event to update views
#   * active editor changes: if JS, show InspectorView and PathView, and update it
# Options for:
# - Highlight is exclusive/inclusive
# - Highlight parents in different shades
# - Disable highlight for GLOBAL
# - Show sidebar (pathbar is always shown?)
# - Turn off syntax highlighting, turn on scope highlighting

plugin.inspections = []
plugin.activeInspection = null

plugin.registerInspections = ->
  atom.workspaceView.eachEditorView (editorView) =>
    editor = editorView.getEditor();
    if editor.getGrammar().name isnt 'JavaScript'
      return

    inspection = new Inspection(editorView, @)
    @inspections.push inspection
    editor.inspection = inspection

plugin.configDefaults =
  highlightScopeInEditor: false
  highlightGlobalScope: false
  #highlightParents: false
  #exclusiveHighlight: false
  showSidebar: true

plugin.activate = (state) ->
  @scopeInspectorView ?= new ScopeInspectorView(@)
  @scopePathView ?= new ScopePathView(@)
  atom.workspaceView.on('pane-container:active-pane-item-changed', @onPaneChanged.bind(this))
  @registerInspections.call(this)

plugin.onPaneChanged = ->
  editor = atom.workspace.getActiveEditor()
  if not editor
    @scopeInspectorView.hide()
    @scopePathView.hide()
    return
  if editor.getGrammar().name isnt 'JavaScript'
    # disable the shit out of the plugin
    @scopeInspectorView.hide()
    @scopePathView.hide()
  else
    @activeInspection = editor.inspection
    @scopeInspectorView.show() if atom.config.get 'scope-inspector.showSidebar'
    @scopePathView.show()

plugin.deactivate = ->
  inspection.destroy() for inspection in @inspections

plugin.serialize = ->
  JSON.stringify(@state)
