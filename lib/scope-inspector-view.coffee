{$, $$, View, ScrollView} = require 'atom'
ScopeView = require './scope-view-single'
Reporter = require './reporter'

module.exports =
class ScopeInspectorView extends ScrollView
  @content: ->
    @div class: 'scope-inspector tool-panel panel-right', =>
      @div class: "scope-inspector-resize-handle"
      @div outlet: 'panelWrapper'

  initialize: (@plugin) ->
    super()
    atom.workspaceView.command "scope-inspector:toggle-sidebar", => @toggle()
    atom.workspaceView.command "scope-inspector:toggle-highlighting", => @toggleHighlighting()
    atom.workspaceView.command "scope-inspector:toggle-breadcrumbs", => @toggleBreadcrumbs()
    atom.workspaceView.command "scope-inspector:toggle-hoisting-indicators", => @toggleHoisting()
    atom.workspaceView.appendToRight(this)
    atom.config.observe 'scope-inspector.showSidebar', => @onToggle()
    @on 'mousedown', '.scope-inspector-resize-handle', (e) => @resizeStarted(e)
    @on 'click', '[data-line]', (e) => @onClickIdentifier(e)
    @width(@plugin.state.sidebarWidth)
    @subviews = []

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    atom.config.toggle 'scope-inspector.showSidebar'

  toggleHighlighting: ->
    atom.config.toggle 'scope-inspector.highlightCurrentScope'

  toggleBreadcrumbs: ->
    atom.config.toggle 'scope-inspector.showBreadcrumbs'

  toggleHoisting: ->
    atom.config.toggle 'scope-inspector.showHoistingIndicators'

  onToggle: ->
    #if atom.config.get('scope-inspector.showSidebar') and not @hasParent()
    #  atom.workspaceView.appendToRight @
    #  @plugin.onPaneChanged()
    #else
    #  @detach()
    if atom.config.get 'scope-inspector.showSidebar'
      @show()
    else
      @hide()

  onClickIdentifier: (e) ->
    #console.log(e)
    el = $ e.currentTarget
    #console.log el
    line = parseInt el.attr('data-line'), 10
    column = parseInt el.attr('data-column'), 10
    Reporter.sendEvent('identifier', 'click')
    #loc = scope.loc.start
    @plugin.activeInspection.editor.setCursorBufferPosition([line, column])
    @plugin.activeInspection.editorView.focus()

  renderScope: (scopes) ->
    @panelWrapper.empty()
    @subviews = []
    if scopes?
      (@subviews.push(new ScopeView(scope)) for scope in scopes)
      @panelWrapper.append view for view in @subviews
    else
      @panelWrapper.append "<ul class='background-message centered'><li>Parsing error</li></ul>"

  # Resize code borrowed from TreeView
  resizeStarted: =>
    $(document.body).on('mousemove', @resizeSidebar)
    $(document.body).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document.body).off('mousemove', @resizeSidebar)
    $(document.body).off('mouseup', @resizeStopped)
    @plugin.state.sidebarWidth = @width()

  resizeSidebar: ({pageX}) =>
    width = $(document.body).width() - pageX
    @width(width)
