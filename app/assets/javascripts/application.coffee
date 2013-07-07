#= require jquery
#= require jquery_ujs
#= require raphael-min
#= require_tree .

jQuery ->
  $(document).ready ->
    initMonthPicker()
    initSelectDateEffect()
    initCalendarCellSelection()

  $(window).load ->
    initRandomProgresses()
    initUpdateDataRequest()


  initMonthPicker = ->
    $('#month-picker li').click ->
      return false if $(this).hasClass('disabled')

      newActive =
        if $(this).hasClass('left')
          $('.active').prev()
        else if $(this).hasClass('right')
          $('.active').next()
        else
          $(this)

      $.get('/events.js', { year: newActive.data('year'), month: newActive.data('month') }, ->
        $('#month-picker li').removeClass('active')
        newActive.addClass('active')

        if $('.active').prev().hasClass('left')
          $('.left').addClass('disabled')
        else
          $('.left').removeClass('disabled')

        if $('.active').next().hasClass('right')
          $('.right').addClass('disabled')
        else
          $('.right').removeClass('disabled')

        initUpdateDataRequest()
      )

  initRandomProgresses = ->
    $('.random-progress').each ->
      $(this).radialProgress($(this).data('value'))

  initSelectDateEffect = ->
    $('#date-panel').click ->
      if $('#calendar').is(':hidden')
        $('#calendar').animate({opacity: 'toggle', 'margin-top': 'toggle'}, 300)
      false

  initUpdateDataRequest = ->
    $.getJSON('/events/updated_data.json', { year: $('.active').data('year'), month: $('.active').data('month') }, (data) ->
      for day in data
        holder = $(".day-holder[data-day = #{day.date}]")

        newHolder = $("<div class='day-holder' data-day='#{day.date}' style='display: none'></div>")
        newHolder.append(holder.find('span').clone())

        if day.event_count > 0
          newHolder.append("<div class='random-progress' data-value='#{day.random_value}'></div>")
          newHolder.append("<div class='event-count'>
                              <p>#{day.event_count}</p>#{if day.event_count == 1 then 'event' else 'events'}
                            </div>")
        else
          newHolder.append("<p class='free-day'>No Events</p>")

        holder.parent().append(newHolder)
        newHolder.find('.random-progress').radialProgress(day.random_value)

        holder.remove()
        newHolder.show()
    )

  initCalendarCellSelection = ->
    $(document).on('click', '.calendar-holder .day-holder', ->
      return false if $(this).hasClass('disabled')

      currentDay = parseInt($(this).find('.day-num').html())
      currentDate = $('#current-date-template').val().replace('X', "0#{currentDay}".substr(-2, 2))

      if $('.start-day').length
        $(this).closest('.day').addClass('end-day')
        $('.day-holder').addClass('disabled')
        $('#date-panel span').append(currentDate)
      else
        $(this).closest('.day').addClass('start-day')
        $('.day-holder').filter( ->
          currentDay >= parseInt($(this).find('.day-num').html())).addClass('disabled')
        $('#date-panel span').html("#{currentDate} - ")
    )
