{$, $$, View, ScrollView} = require 'atom-space-pen-views'
ScopeView = require './scope-view-single'
Reporter = require './reporter'

module.exports =
class ScopeInspectorView extends ScrollView
  @content: ->
    @div class: 'scope-inspector', =>
      @div class: "scope-inspector-resize-handle"
      @div outlet: 'panelWrapper'

  initialize: (@plugin) ->
    super()
    atom.commands.add 'atom-text-editor',
      "scope-inspector:toggle-sidebar": => @toggle()
      "scope-inspector:toggle-highlighting": => @toggleHighlighting()
      "scope-inspector:toggle-breadcrumbs": => @toggleBreadcrumbs()
      "scope-inspector:toggle-hoisting-indicators": => @toggleHoisting()
    atom.workspace.addRightPanel
      item: @
    atom.config.observe 'scope-inspector.showSidebar', => @onToggle()
    @on 'mousedown', '.scope-inspector-resize-handle', (e) => @resizeStarted(e)
    @on 'click', '[data-line]', (e) => @onClickIdentifier(e)
    @width(@plugin.state.sidebarWidth)
    @subviews = []

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    atom.config.set 'scope-inspector.showSidebar', not atom.config.get 'scope-inspector.showSidebar'

  toggleHighlighting: ->
    atom.config.set 'scope-inspector.highlightCurrentScope', not atom.config.get 'scope-inspector.highlightCurrentScope'

  toggleBreadcrumbs: ->
    atom.config.set 'scope-inspector.showBreadcrumbs', not atom.config.get 'scope-inspector.showBreadcrumbs'

  toggleHoisting: ->
    atom.config.set 'scope-inspector.showHoistingIndicators', not atom.config.get 'scope-inspector.showHoistingIndicators'

  onToggle: ->
    if atom.config.get 'scope-inspector.showSidebar'
      @show()
    else
      @hide()

  onClickIdentifier: (e) ->
    el = $ e.currentTarget
    line = parseInt el.attr('data-line'), 10
    column = parseInt el.attr('data-column'), 10
    Reporter.sendEvent('identifier', 'click')
    @plugin.activeInspection.editor.setCursorBufferPosition([line, column])
    #atom.views.get(@plugin.activeInspection.editor)?.focus()

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
