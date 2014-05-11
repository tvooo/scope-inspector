{$, $$, View, ScrollView} = require 'atom'
ScopeView = require './scope-view-single'
_ = require 'lodash'

module.exports =
class ScopeInspectorView extends ScrollView
  @content: ->
    @div class: 'scope-inspector tool-panel panel-right', =>
      @div class: "scope-inspector-resize-handle"
      @div outlet: 'panelWrapper'

  initialize: (@plugin) ->
    super()
    atom.workspaceView.command "scope-inspector:toggle-sidebar", => @toggle()
    atom.workspaceView.appendToRight(this)
    atom.config.observe 'scope-inspector.showSidebar', => @onToggle()
    @on 'mousedown', '.scope-inspector-resize-handle', (e) => @resizeStarted(e)
    @width(@plugin.state.sidebarWidth)
    @subviews = []

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    atom.config.toggle 'scope-inspector.showSidebar'

  onToggle: ->
    if atom.config.get('scope-inspector.showSidebar') and not @hasParent()
      atom.workspaceView.appendToRight @
      @plugin.onPaneChanged()
    else
      @detach()

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
