{View} = require 'atom'

module.exports =
class ScopeView extends View
  @content: (scope) ->
    @div class: 'scope-view inset-panel', =>
      @div class: "panel-heading", scope.name
      @ul class: "panel-body padded list-group", =>
        if scope.params?
          for id in scope.params
            @li class: "list-item", =>
              @span class: "no-icon #{'is-shadowing' if id.shadows} #{'is-shadowed' if id.shadowedBy.length}", id.name
              #@li class: , id.name, =>
              if id.shadowedBy.length
                @span class: 'argument', "shadowed"
              else
                @span class: 'argument', "param"
        for id in scope.variables
          @li class: "list-item", =>
            @span class: "#{if id.hoisted then 'is-hoisted icon icon-chevron-up' else 'no-icon'} #{'is-shadowing' if id.shadows} #{'is-shadowed' if id.shadowedBy.length}", id.name
            if id.shadowedBy.length
              @span class: 'argument', "shadowed"
        for id in scope.functions
          @li class: "list-item", =>
            @span class: "no-icon #{'is-shadowing' if id.shadows} #{'is-shadowed' if id.shadowedBy.length}", id.name
            if id.shadowedBy.length
              @span class: 'argument', "shadowed"
            else
              @span class: 'argument', "()"

  destroy: ->
    @detach()

  rerender: (scope) ->
    @replaceWith new ScopeView(scope)
