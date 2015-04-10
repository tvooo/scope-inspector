{$, $$, View} = require 'atom-space-pen-views'
Reporter = require './reporter'

module.exports =
class ScopePathView extends View
  @content: (plugin) ->
    @div class: 'scope-path tool-panel panel-bottom', =>
      @div class: 'inset-panel padded', =>
        @div class: 'scope-path-buttons', outlet: 'panelWrapper'

  initialize: (@plugin) ->
    atom.workspace.addBottomPanel
      item: @
    @onToggle()

  registerAdditionalEvents: ->
    atom.config.observe 'scope-inspector.showBreadcrumbs', =>
      @onToggle()

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
      for scope, i in scopePath.reverse()
        button = $ "<div class='scope-breadcrumb'><span class='scope-breadcrumb-text'>#{scope.name}</span></div>"
        if i < scopePath.length-1
          button.append "<i class='icon icon-chevron-right'></i>"
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
    atom.views.getView(@plugin.activeInspection.editor).focus()
