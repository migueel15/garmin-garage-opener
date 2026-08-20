import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Communications;

class GarageDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Lang.Boolean {
        WatchUi.pushView(
            new Rez.Menus.MainMenu(),
            new GarageMenuDelegate(),
            WatchUi.SLIDE_UP
        );

        return true;
    }

    function onBack() as Lang.Boolean {
        System.println("pulsado back");
        return false;
    }

    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        var coords = event.getCoordinates();

        var x = coords[0];
        var y = coords[1];

        System.println("Tap: " + x + ", " + y);

        // Centro y radio de tu círculo
        var cx = 130;
        var cy = 130;
        var radius = 100;

        var dx = x - cx;
        var dy = y - cy;

        if ((dx * dx + dy * dy) <= (radius * radius)) {
            pulseShelly();
            return true;
        }

        return false;
    }

    function pulseShelly() as Void {
    		System.println("Mandando peticion...!");
        var url = Application.Properties.getValue("backendUrl");
        var apiToken = Application.Properties.getValue("apiToken");

        Communications.makeWebRequest(
            url,
            {
            },
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Authorization" => "Bearer " + apiToken,
                    "Accept" => "application/json"
                }
            },
            method(:onResponse)
        );
    }

    function onResponse(
		responseCode as Lang.Number,
		data as Null or Lang.Dictionary or Lang.String or PersistedContent.Iterator
		) as Void {
        System.println("HTTP code: " + responseCode);
        System.println("Response: " + data);
    }
}
