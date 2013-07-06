#= require jquery
#= require jquery_ujs
#= require raphael-min
#= require_tree .

jQuery ->
  $(document).ready ->
    initRandomProgresses()
    initCalendarCellSelection()


  initRandomProgresses = ->
    $('.random-progress').each ->
      $(this).radialProgress($(this).data('value'))

  initCalendarCellSelection = ->
    $('#calendar-holder .day-holder').on('click', ->
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
