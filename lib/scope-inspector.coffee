Inspection = require './inspection'
ScopeInspectorView = require './scope-inspector-view'
ScopePathView = require './scope-path-view'
Reporter = require './reporter'
crypto = require 'crypto'

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
    showBreadcrumbs: true
    showHoistingIndicators: true
    evaluationDelay: 200
    evaluateOnlyOnSave: false
    trackUsageMetrics: true
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
    atom.config.observe 'scope-inspector.showBreadcrumbs', ->
      Reporter.sendEvent('showBreadcrumbs', if atom.config.get 'scope-inspector.showBreadcrumbs' then 'enabled' else 'disabled')
    atom.config.observe 'scope-inspector.showHoistingIndicators', ->
      Reporter.sendEvent('showHoistingIndicators', if atom.config.get 'scope-inspector.showHoistingIndicators' then 'enabled' else 'disabled')

  onPaneChanged: ->
    editor = atom.workspace.getActiveEditor()
    if not editor
      @scopeInspectorView?.hide()
      @scopePathView?.hide()
      return
    if editor.getGrammar().name isnt 'JavaScript'
      @scopeInspectorView?.hide()
      @scopePathView?.hide()
    else
      @activeInspection = editor.inspection
      @scopeInspectorView.show() if atom.config.get 'scope-inspector.showSidebar'
      @scopePathView.show() if atom.config.get 'scope-inspector.showBreadcrumbs'

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
