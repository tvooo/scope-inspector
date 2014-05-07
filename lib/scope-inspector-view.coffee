{$$, View} = require 'atom'
ScopeView = require './scope-view-single'
_ = require 'lodash'

module.exports =
class ScopeInspectorView extends View
  @content: (scope) ->
    @div class: 'scope-inspector tool-panel panel-right', =>
      @div outlet: 'panelWrapper', =>
        @subview 'scopeView', new ScopeView(scope) if scope?

  initialize: (serializeState) ->
    atom.workspaceView.command "scope-inspector:toggle", => @toggle()
    atom.workspaceView.appendToRight(this)
    @subviews = []


  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "ScopeInspectorView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.appendToRight(this)

  renderScope: (scopes) ->
    console.debug "Rendering scope"

    @panelWrapper.empty()
    @subviews = []

    (@subviews.push(new ScopeView(scope)) for scope in scopes)

    @panelWrapper.append view for view in @subviews
