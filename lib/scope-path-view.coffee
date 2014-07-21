{$, $$, View} = require 'atom'
Reporter = require './reporter'

module.exports =
class ScopePathView extends View
  @content: (plugin) ->
    @div class: 'scope-path tool-panel panel-bottom', =>
      @div class: 'inset-panel padded', =>
        @div class: 'btn-group scope-path-buttons', outlet: 'panelWrapper'

  initialize: (@plugin) ->
    atom.workspaceView.appendToBottom @
    @onToggle()

  registerAdditionalEvents: ->
    atom.config.observe 'scope-inspector.showBreadcrumbs', =>
      @onToggle()

  # Tear down any state and detach
  destroy: ->
    @detach()

  onToggle: ->
    if atom.config.get 'scope-inspector.showBreadcrumbs'
      @show()
    else
      @hide()

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

  onEnterButton: (scope, event) ->
    Reporter.sendEvent('path-button', 'hover')
    @plugin.activeInspection.focusScope(scope)

  onLeaveButton: ->
    @plugin.activeInspection.focusScope(null)

  onClickButton: (scope, event) ->
    Reporter.sendEvent('path-button', 'click')
    loc = scope.loc.start
    @plugin.activeInspection.editor.setCursorBufferPosition([loc.line-1, loc.column])
    @plugin.activeInspection.editorView.focus()
