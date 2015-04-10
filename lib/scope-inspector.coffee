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
    atom.workspace.observeTextEditors (editor) =>
      #editorView.command('editor:grammar-changed', => @updateInspection(editorView))
      atom.commands.add 'atom-workspace',
        'editor:grammar-changed': => @updateInspection(editor)
      @updateInspection(editor)

  updateInspection: (editor) ->
    if editor.getGrammar().name isnt 'JavaScript'
      return

    inspection = new Inspection(editor, @)
    @inspections.push inspection
    editor.inspection = inspection

  config:
    highlightGlobalScope:
      type: 'boolean'
      default: false
    showSidebar:
      type: 'boolean'
      default: true
    showBreadcrumbs:
      type: 'boolean'
      default: true
    showHoistingIndicators:
      type: 'boolean'
      default: true
    evaluationDelay:
      type: 'integer'
      default: 200
      minimum: 0
      maximum: 2000
    evaluateOnlyOnSave:
      type: 'boolean'
      default: false
    trackUsageMetrics:
      type: 'boolean'
      default: true
    userId:
      type: 'string'
      default: ""

  activate: (@state) ->
    @scopeInspectorView ?= new ScopeInspectorView(@)
    @scopePathView ?= new ScopePathView(@)
    @scopePathView.registerAdditionalEvents()
    atom.workspace.onDidChangeActivePaneItem(@onPaneChanged.bind(this))
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
    editor = atom.workspace.getActiveTextEditor()
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
