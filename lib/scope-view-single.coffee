{View} = require 'atom'

module.exports =
class ScopeView extends View
  @content: (scope) ->
    @div class: 'scope-view inset-panel', =>
      @div class: "panel-heading", scope.name
      @ul class: "panel-body padded", =>
        if scope.params?
          for param in scope.params
            @li param.name, =>
              @span class: 'argument', "param"
        for variable in scope.variables
          @li variable.name
        for func in scope.functions
          @li func.name, =>
            @span class: 'argument', "()"

  destroy: ->
    @detach()

  rerender: (scope) ->
    @replaceWith new ScopeView(scope)
