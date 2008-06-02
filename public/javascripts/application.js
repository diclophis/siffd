/* JonBardin */

var map;
var business_icon = new GIcon(G_DEFAULT_ICON, "/images/business.png");

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
  if (GBrowserIsCompatible()) {
    map = new GMap2($("map"));
    map.setCenter(new GLatLng($F('latitude'), $F('longitude')), 13);
    map.addControl(new GSmallMapControl());
    map.addControl(new GMapTypeControl());
    map.getInfoWindow().enableMaximize();

    //alert($F('latitude'));
    //alert($F('longitude'));
  }

  $$(".event").each(function(an_event) {
    id = an_event.id;
    geo = an_event.select(".geo").first();
    latitude = geo.select(".latitude").first().innerHTML;
    longitude = geo.select(".longitude").first().innerHTML;
    if (latitude.length && longitude.length) {
      point = new GLatLng(latitude, longitude);
      marker = new GMarker(point);
      marker.value = id;
      GEvent.addListener(marker, "click", function() {
        name = $(this.value).select(".name").first().innerHTML;
        description = $(this.value).select(".description").first().innerHTML;
        this.openInfoWindowHtml(name, {
          maxContent: description, 
          maxTitle: name
        });
        //this.openInfoWindowHtml($(this.value));
      });
      map.addOverlay(marker);
    }
  });
  $$(".business").each(function(an_event) {
    id = an_event.id;
    geo = an_event.select(".geo").first();
    latitude = geo.select(".latitude").first().innerHTML;
    longitude = geo.select(".longitude").first().innerHTML;
    if (latitude.length && longitude.length) {
      point = new GLatLng(latitude, longitude);
      marker = new GMarker(point, business_icon);
      marker.value = id;
      GEvent.addListener(marker, "click", function() {
        name = $(this.value).select(".name").first().innerHTML;
        this.openInfoWindowHtml(name);
      });
      map.addOverlay(marker);
    }
  });
  $$("#focusers a").each(function(focuser) {
    Event.observe(focuser, "click", function(click) {
      Event.stop(click);
      id = this.id.replace("focus_", "");
      ["events", "businesses", "neighbors"].each(function(list) {
        $(list).hide();
      });
      $(id).show();
    });
    $(focuser.id.replace("focus_", "")).hide();
  });
});
