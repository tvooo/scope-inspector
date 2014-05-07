{$$, View} = require 'atom'

module.exports =
class ScopePathView extends View
  @content: () ->
    @div class: 'scope-path tool-panel panel-bottom', =>
      @div outlet: 'panelWrapper', =>
        @div "hallo welt"

  initialize: (serializeState) ->
    atom.workspaceView.appendToBottom(this)

  # Tear down any state and detach
  destroy: ->
    @detach()

  renderScope: (scopePath) ->
    console.debug "Rendering statusbar"
    @panelWrapper.empty()
    @panelWrapper.append "<button class='btn'>#{scope.name}</button>" for scope in scopePath.reverse()
