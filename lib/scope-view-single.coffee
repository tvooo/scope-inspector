{View} = require 'atom'

module.exports =
class ScopeView extends View
  @content: (scope) ->
    @div class: 'scope-view inset-panel', =>
      @div class: "panel-heading", scope.name
      @ul class: "panel-body padded", =>
        for variable in scope.variables
          @li variable.name, =>
            @span class: 'argument', "arg"

  destroy: ->
    @detach()

  rerender: (scope) ->
    @replaceWith new ScopeView(scope)
