{$, $$, View} = require 'atom'
Reporter = require './reporter'

module.exports =
class ScopePathView extends View
  @content: (plugin) ->
    @div class: 'scope-path tool-panel panel-bottom', =>
      @div class: 'inset-panel padded', =>
        @div class: 'btn-group scope-path-buttons', outlet: 'panelWrapper'
        @div class: 'btn-group scope-options', =>
          @button class: "btn #{'selected' if atom.config.get 'scope-inspector.highlightGlobalScope'}", outlet: 'btnToggleHighlightGlobal', click: 'toggleHighlightGlobal','Highlight Global'
          @button class: "btn #{'selected' if atom.config.get 'scope-inspector.showSidebar'} icon icon-list-unordered", outlet: 'btnToggleSidebar', click: 'toggleSidebar'


  initialize: (@plugin) ->
    atom.workspaceView.appendToBottom(this)

  registerAdditionalEvents: ->
    atom.config.observe 'scope-inspector.showSidebar', =>
      @btnToggleSidebar[if atom.config.get 'scope-inspector.showSidebar' then 'addClass' else 'removeClass']('selected')
    atom.config.observe 'scope-inspector.highlightGlobalScope', =>
      @btnToggleHighlightGlobal[if atom.config.get 'scope-inspector.highlightGlobalScope' then 'addClass' else 'removeClass']('selected')

  # Tear down any state and detach
  destroy: ->
    @detach()

  renderScope: (scopePath) ->
    @panelWrapper.empty()
    if scopePath?
      for scope in scopePath.reverse()
        button = $ "<button class='btn'>#{scope.name}</button>"
        button.on 'click', @onClickButton.bind(this, scope)
        button.on 'mouseover', @onEnterButton.bind(this, scope)
        button.on 'mouseout', @onLeaveButton.bind(this)
        @panelWrapper.append button
    else
      @panelWrapper.append "<div class='text-subtle'>Parsing error</div>"

  toggleHighlightGlobal: (event, element) ->
    atom.config.toggle 'scope-inspector.highlightGlobalScope'
    @btnToggleHighlightGlobal.blur()

  toggleSidebar: (event, element) ->
    @plugin.scopeInspectorView.toggle()
    @btnToggleSidebar.blur()

  onEnterButton: (scope, event) ->
    Reporter.sendEvent('path-button', 'hover')
    @plugin.activeInspection.focusScope(scope)

  onLeaveButton: ->
    #@plugin.activeInspection.onCursorMoved()
    @plugin.activeInspection.focusScope(null)

  onClickButton: (scope, event) ->
    Reporter.sendEvent('path-button', 'click')
    loc = scope.loc.start
    @plugin.activeInspection.editor.setCursorBufferPosition([loc.line-1, loc.column])
    @plugin.activeInspection.editorView.focus()
