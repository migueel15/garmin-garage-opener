import Toybox.Application;
import Toybox.WatchUi;

class GarageApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
				if (Application.Storage.getValue("start_time") == null) {
						Application.Storage.setValue("start_time", "23:00");
				}

				if (Application.Storage.getValue("end_time") == null) {
						Application.Storage.setValue("end_time", "08:00");
				}

				if (Application.Storage.getValue("block_sleep_hours") == null) {
						Application.Storage.setValue("block_sleep_hours", false);
				}
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new GarageView();
        return [ view, new GarageDelegate(view) ];
    }
}
