import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application;

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
				if (id == :block_sleep_hours){
					var toggle = item as WatchUi.ToggleMenuItem;
					Application.Storage.setValue("block_sleep_hours", toggle.isEnabled());
				}

				if (id == :start_time) {
					openPicker(item, "Horario Inicio", "start_time");
				}

				if (id == :end_time) {
					openPicker(item, "Horario Cierre", "end_time");
				}

        System.println(id);
    }

		function openPicker(item, titulo, id) {
			WatchUi.pushView(new TimePicker(titulo,id), new TimePickerDelegate(id, item), WatchUi.SLIDE_IMMEDIATE);
			return true;
		}
}
