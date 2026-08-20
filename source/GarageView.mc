import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.System;
import Toybox.Position;

class GarageView extends WatchUi.View {

    var lat = null;
    var lon = null;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        startTracking();
    }

    function startTracking() as Void {
        System.println("empezando tracking");
        Position.enableLocationEvents(
            Position.LOCATION_CONTINUOUS,
            method(:onPosition)
        );
    }

    function onPosition(info as Position.Info)as Void{
        System.println("llamando onPosition");
        if (info.position == null){
            System.println("Esperando posicion...");
            return;
        }

        var coords = info.position.toDegrees();
        lat = coords[0];
        lon = coords[1];

        System.println(lat);
        System.println(lon);
        WatchUi.requestUpdate();
    }


    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
				dc.fillCircle(dc.getWidth()/2, dc.getHeight()/2,100);
				System.println(Application.Properties.getValue("apiToken"));
    }

    function onHide() as Void {
        Position.enableLocationEvents(
            Position.LOCATION_DISABLE,
            null
        );
    }
}
