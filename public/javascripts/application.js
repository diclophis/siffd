/* JonBardin */

Event.observe(window, "load", function () {
  Calendar.setup({
    dateField : 'date',
    triggerElement : 'calendar'
    //selectHandler : function (calendar, selected_date) {
      //alert(selected_date);
      //alert($F('date'));
      //alert(selected_date);
    //}
  })
});
