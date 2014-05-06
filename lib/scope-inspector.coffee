ScopeInspectorView = require './scope-inspector-view'

module.exports =
  scopeInspectorView: null

  activate: (state) ->
    @scopeInspectorView = new ScopeInspectorView(state.scopeInspectorViewState)

  deactivate: ->
    @scopeInspectorView.destroy()

  serialize: ->
    scopeInspectorViewState: @scopeInspectorView.serialize()
