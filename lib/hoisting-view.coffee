_ = require 'lodash'
{$, View, Range, Point} = require 'atom'

module.exports =
class HostingView extends View
  @content: ->
    @div class: 'violation', =>
      @div class: 'violation-arrow'
      @div class: 'violation-border'

  initialize: (@inspection) ->
    @editorView = @inspection.editorView
    @editor = @editorView.getEditor()

  destroy: ->
    @detach()

  initializeSubviews: ->
    @arrow = @find('.violation-arrow')
    @arrow.addClass("violation-#{@violation.severity}")

    @area = @find('.violation-area')
    @area.addClass("violation-#{@violation.severity}")

  render: (scope) ->
    @editorView.find('.underlayer .hoisting').hide().remove()
    hoistedIdentifiers = scope.getHoistedIdentifiers()
    return unless hoistedIdentifiers.length

    startPosition = @editorView.pixelPositionForBufferPosition([scope.hoistingPosition.start.line-1, scope.hoistingPosition.start.column])
    lineHeight = @editorView.lineHeight

    line = @editorView.lineElementForScreenRow(scope.hoistingPosition.start.line-1).find('span.source')
    @width(line.width() - startPosition.left + 5)
    @height lineHeight

    @css
      top: startPosition.top
      left: startPosition.left - 5

    @setTooltip "Hoisted identifiers: " + _.pluck(hoistedIdentifiers, 'name').join(', ')
    @editorView.find('.overlayer').append(@)

  trackEdit: ->
    # :persistent -
    # Whether to include this marker when serializing the buffer. Defaults to true.
    #
    # :invalidate -
    # Determines the rules by which changes to the buffer *invalidate* the
    # marker. Defaults to 'overlap', but can be any of the following:
    # * 'never':
    #     The marker is never marked as invalid. This is a good choice for
    #     markers representing selections in an editor.
    # * 'surround':
    #     The marker is invalidated by changes that completely surround it.
    # * 'overlap':
    #     The marker is invalidated by changes that surround the start or
    #     end of the marker. This is the default.
    # * 'inside':
    #     The marker is invalidated by a change that touches the marked
    #     region in any way. This is the most fragile strategy.
    options = { invalidation: 'inside', persistent: false }
    @marker = @editor.markScreenRange(@getCurrentScreenRange(), options)
    @marker.on 'changed', (event) =>
      # Head and Tail: Markers always have a head and sometimes have a tail.
      # If you think of a marker as an editor selection, the tail is the part that's stationary
      # and the head is the part that moves when the mouse is moved.
      # A marker without a tail always reports an empty range at the head position.
      # A marker with a head position greater than the tail is in a "normal" orientation.
      # If the head precedes the tail the marker is in a "reversed" orientation.
      @screenStartPosition = event.newTailScreenPosition
      @screenEndPosition = event.newHeadScreenPosition
      @isValid = event.isValid

      if @isValid
        if @isVisibleMarkerChange(event)
          # TODO: EditorView::pixelPositionForScreenPosition lies when a line above the marker was
          #   removed and it was invoked from this marker's "changed" event.
          setImmediate =>
            @showHighlight()
            @toggleTooltipWithCursorPosition()
        else
          # Defer repositioning views that are currently outside of visibile area of scroll view.
          # This is important to avoid UI freeze when so many markers are changed by a single
          # modification (e.g. inserting/deleting the first line in the file).

          # Hide the views for now, so that the repositioning-pending views won't be shown in the
          # visible area of the scroll view.
          @hide()

          # This should be held by each ViolationView instance. Otherwise it will be called only
          # once for all instance events.
          @scheduleDeferredShowHighlight ?= _.debounce(@showHighlight, 500)
          @scheduleDeferredShowHighlight()
      else
        @hideHighlight()
        @tooltip('hide')

  isVisibleMarkerChange: (event) ->
    editorFirstVisibleRow = @editorView.getFirstVisibleScreenRow()
    editorLastVisibleRow = @editorView.getLastVisibleScreenRow()
    [event.oldTailScreenPosition, event.newTailScreenPosition].some (position) ->
      editorFirstVisibleRow <= position.row <= editorLastVisibleRow

  beforeRemove: ->
    #@marker?.destroy()
