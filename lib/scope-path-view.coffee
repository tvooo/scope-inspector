{$, $$, View} = require 'atom'

module.exports =
class ScopePathView extends View
  @content: (plugin) ->
    @div class: 'scope-path tool-panel panel-bottom', =>
      @div class: 'inset-panel padded', =>
        @div class: 'btn-group scope-path-buttons', outlet: 'panelWrapper'
        @div class: 'btn-group scope-options', =>
          @button class: "btn #{'selected' if atom.config.get 'scope-inspector.highlightGlobalScope'}", click: 'toggleHighlightGlobal','Highlight Global'
          @button class: 'btn icon icon-list-unordered', outline: 'btnToggleSidebar', =>
            console.log @
            #console.log @btnToggleSidebar
            #@btnToggleSidebar.setTooltip(title


  initialize: (@plugin) ->
    atom.workspaceView.appendToBottom(this)

  # Tear down any state and detach
  destroy: ->
    @detach()

  renderScope: (scopePath) ->
    console.debug "Rendering statusbar"
    @panelWrapper.empty()
    for scope in scopePath.reverse()
      button = $ "<button class='btn'>#{scope.name}</button>"
      button.on 'click', @onClickButton.bind(this, scope)
      @panelWrapper.append button

  toggleHighlightGlobal: (event, element) ->
    element.toggleClass('selected')
    atom.config.set 'scope-inspector.highlightGlobalScope', element.is('.selected')

  onClickButton: (scope, event) ->
    #@plugin.
    console.log "scope is #{scope}"
    console.log @plugin.activeInspection
    loc = scope.loc.start
    console.log [loc.line-1, loc.column]
    @plugin.activeInspection.editor.setCursorBufferPosition([loc.line-1, loc.column])
    @plugin.activeInspection.editorView.focus()
