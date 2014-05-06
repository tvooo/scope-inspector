{View} = require 'atom'

module.exports =
class ScopeInspectorView extends View
  @content: ->
    @div class: 'scope-inspector overlay from-top', =>
      @div "The ScopeInspector package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "scope-inspector:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "ScopeInspectorView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
