import Toybox.Application;
import Toybox.WatchUi;

class GarageApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new GarageView();
        return [ view, new GarageDelegate(view) ];
    }
}
