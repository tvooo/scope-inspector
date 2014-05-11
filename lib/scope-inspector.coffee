_ = require 'lodash'
#Subscriber = require('emissary').Subscriber
Inspection = require './inspection'
ScopeInspectorView = require './scope-inspector-view'
ScopePathView = require './scope-path-view'
Reporter = require './reporter'
crypto = require 'crypto'

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

class ScopeInspector

  constructor: ->
    @inspections = []
    @activeInspection = null

  registerInspections: ->
    atom.workspaceView.eachEditorView (editorView) =>

      editor = editorView.getEditor();
      editorView.command('editor:grammar-changed', => @updateInspection(editorView))
      @updateInspection(editorView)

  updateInspection: (editorView) ->
    editor = editorView.getEditor();
    if editor.getGrammar().name isnt 'JavaScript'
      return

    inspection = new Inspection(editorView, @)
    @inspections.push inspection
    editor.inspection = inspection

  configDefaults:
    highlightGlobalScope: false
    showSidebar: true
    trackUsageMetrics: false
    userId: ""

  activate: (@state) ->
    @scopeInspectorView ?= new ScopeInspectorView(@)
    @scopePathView ?= new ScopePathView(@)
    @scopePathView.registerAdditionalEvents()
    atom.workspaceView.on('pane-container:active-pane-item-changed', @onPaneChanged.bind(this))
    @registerInspections.call(this)
    @scopeInspectorView.onToggle()
    if atom.config.get('scope-inspector.userId')
      @begin(@state?.sessionLength)
    else
      @getUserId (userId) -> atom.config.set('scope-inspector.userId', userId)
      @begin(@state?.sessionLength)
    atom.config.observe 'scope-inspector.showSidebar', ->
      Reporter.sendEvent('showSidebar', if atom.config.get 'scope-inspector.showSidebar' then 'enabled' else 'disabled')
    atom.config.observe 'scope-inspector.highlightGlobalScope', ->
      Reporter.sendEvent('highlightGlobalScope', if atom.config.get 'scope-inspector.highlightGlobalScope' then 'enabled' else 'disabled')

  onPaneChanged: ->
    editor = atom.workspace.getActiveEditor()
    if not editor
      @scopeInspectorView.hide()
      @scopePathView.hide()
      return
    if editor.getGrammar().name isnt 'JavaScript'
      @scopeInspectorView.hide()
      @scopePathView.hide()
    else
      @activeInspection = editor.inspection
      @scopeInspectorView.show() if atom.config.get 'scope-inspector.showSidebar'
      @scopePathView.show()

  begin: (sessionLength) ->
    @sessionStart = Date.now()

    Reporter.sendEvent('inspector', 'ended', sessionLength) if sessionLength
    Reporter.sendEvent('inspector', 'started')

  getUserId: (callback) ->
    require('getmac').getMac (error, macAddress) =>
      if error?
        callback require('node-uuid').v4()
      else
        callback crypto.createHash('sha1').update(macAddress, 'utf8').digest('hex')

  deactivate: ->
    inspection.destroy() for inspection in @inspections
    @inspections = []
    @scopeInspectorView.destroy()
    @scopePathView.destroy()

  serialize: ->
    sidebarWidth: @scopeInspectorView.width()
    sessionLength: Date.now() - @sessionStart


module.exports = new ScopeInspector()
