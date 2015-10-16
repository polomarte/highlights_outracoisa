class App.PrioritizationPage
  constructor: ->
    new App.ValuesContainer
    new App.PrioritizationScroll
    new App.Value(el) for el in $('#values-container .value')
    new App.Slot(el) for el in $('#values-container .slot')

    @submitBar = new App.Components.SubmitBar $('#submit-bar')

    $('#values-container').on 'fill', => @submitBar.enableSubmit()
    $('#values-container').on 'unfill', => @submitBar.disableSubmit()

class App.ValuesContainer
  constructor: ->
    @container = $('#values-container')

    @container.on 'value:dragstart', @onValueDragStart
    @container.on 'slot:drop', @onSlotDrop

  onValueDragStart: (ev, value, originalEv) =>
    @draggedValue = value

  onSlotDrop: (ev, slot, originalEv) =>
    slot.receive(@draggedValue)

    if @isLast()
      @container.trigger('fill')
    else
      @container.trigger('unfill')

  isLast: ->
    slots           = $('#values-items-wrapper .slot')
    slotCount       = slots.length
    slotFilledCount = slots.find('.value').length
    slotCount == slotFilledCount

class App.Value
  constructor: (el) ->
    @value = $(el)
    @value.data('value', @)
    @id      = App.Utils.parseId @value
    @html    = @value.wrap()
    @popOver = $('[data-toggle]', @value)
    @initPopover()

    @value.on 'dragstart', @onDragStart
    @value.on 'dragend', @onDragEnd

  initPopover: ->
    # Reinitialize popup because placement can be changed when value is dropped.
    clone = @popOver.clone()
    clone.appendTo @popOver.parent()
    @popOver.remove()
    @popOver = clone

    @popOver.popover
      placement: @popOverPlacement()

    @popOver.on 'show.bs.popover', ->
      App.Utils.highlight $('.popover.in'), -> $('[data-toggle]').popover('hide')

  popOverPlacement: ->
    currentContainer = @value.parents('.values-container')[0]
    rightContainer   = $('.values-container').last()[0]

    if currentContainer == rightContainer then 'left'else 'right'

  onDragStart: (ev) =>
    ev.originalEvent.dataTransfer.setData "...", "..." # Firefox Hack
    @value.trigger('value:dragstart', [@, ev])
    @value.addClass('source')

  onDragEnd: (ev) =>
    @value.removeClass('source')

class App.Slot
  constructor: (el) ->
    @slot         = $(el)
    @slot.data('slot', @)
    @valueWrapper = @slot.find('.value-wrapper')

    @slot.on 'dragover', @onDragOver
    @slot.on 'dragenter', @onDragEnter
    @slot.on 'dragleave', @onDragLeave
    @slot.on 'drop', @onDrop

  receive: (value) =>
    sourceSlot = value.value.parents('.slot')
    .find('input[name$="[value_id]"]').attr('value', null)

    @updateValueFields(value)
    @valueWrapper.html value.html
    value.initPopover()
    value.value.removeClass('source')

  updateValueFields: (value) ->
    @slot.find('input[name$="[value_id]"]').attr('value', value.id)

  isFilled: ->
    !!@slot.find('.value').length

  isSourceSlot: ->
    @slot.find('.value').hasClass('source')

  onDragOver: (ev) =>
    ev.preventDefault() unless @isFilled()

  onDragEnter: (ev) =>
    @slot.addClass('highlight')

  onDragLeave: (ev) =>
    @slot.removeClass('highlight')

  onDrop: (ev) =>
    @slot.trigger('slot:drop', [@, ev])
    @slot.removeClass('highlight')

class App.PrioritizationScroll
  constructor: ->
    @body            = $('body')
    @topAreaLimit    = 100
    @bottomAreaLimit = $(window).height() - @topAreaLimit

    # @buildDebugMarkup()

    $(window).on 'drag',       @onMouseMove
    $(window).on 'dragstart',  @startPooling
    $(window).on 'dragend',    @stopPooling
    $(window).on 'mousewheel', => @isScrolling = true

  startPooling: =>
    @pooling = setInterval((=>
      return if !@isInTopArea() && !@isInBottomArea()
      return if @body.is(':animated')
      return if @isScrolling

      if @isInTopArea()
        offset = ((@topAreaLimit - @currentMouseY) * 0.3) * -1
      else
        offset = ((@currentMouseY - @bottomAreaLimit) * 0.3)

      @body.animate({scrollTop: @body.scrollTop() + offset}, 30, 'linear')
    ), 50)

  stopPooling: =>
    clearInterval(@pooling)

  onMouseMove: (ev) =>
    return if ev.originalEvent.clientY == 0
    @lastMouseY = @currentMouseY
    @currentMouseY = ev.originalEvent.clientY

    if @isMouseInNewPosition() && !@isInTopArea() && !@isInBottomArea()
      @isScrolling = false

  isInTopArea: ->
    @currentMouseY < @topAreaLimit

  isInBottomArea: ->
    @currentMouseY > @bottomAreaLimit

  isMouseInNewPosition: ->
    @currentMouseY != @lastMouseY

  buildDebugMarkup: ->
    sharedCSS =
      position:     'fixed'
      width:        '100%'
      'border-top': '1px solid red'

    @topArea = $("<div></div>").appendTo('body').css(
      $.extend(sharedCSS, {top: @topAreaLimit + 'px'}))

    @bottomArea = $("<div></div>").appendTo('body').css(
      $.extend(sharedCSS, {top: @bottomAreaLimit + 'px'}))

class App.PrioritizationFeedbackPage
  constructor: ->
    new App.Value(el) for el in $('#values-container .value')
