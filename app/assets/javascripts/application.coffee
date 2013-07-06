#= require jquery
#= require jquery_ujs
#= require raphael-min
#= require_tree .

jQuery ->
  $(document).ready ->
    initRandomProgresses()


  initRandomProgresses = ->
    $('.random-progress').each ->
      $(this).radialProgress($(this).data('value'))
