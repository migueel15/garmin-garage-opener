import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

const FACTORY_COUNT_24_HOUR = 3;
const FACTORY_COUNT_12_HOUR = 4;
const MINUTE_FORMAT = "%02d";

//! Picker that allows the user to choose a time
class TimePicker extends WatchUi.Picker {

	var _titulo;
	var _storageID;

    //! Constructor
    public function initialize(titulo, id) {
			_titulo = titulo;
			_storageID = id;

        var title = new WatchUi.Text({:text=>titulo, :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
        var factories;

        if (System.getDeviceSettings().is24Hour) {
            factories = new Array<PickerFactory or Text>[$.FACTORY_COUNT_24_HOUR];
            factories[0] = new NumberFactory(0, 23, 1, {});
        } else {
            factories = new Array<PickerFactory or Text>[$.FACTORY_COUNT_12_HOUR];
            factories[0] = new NumberFactory(1, 12, 1, {});
            factories[3] = new WordFactory([Rez.Strings.am, Rez.Strings.pm], {});
        }

        factories[1] = new WatchUi.Text({:text=>":", :font=>Graphics.FONT_MEDIUM,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER, :color=>Graphics.COLOR_WHITE});
        factories[2] = new NumberFactory(0, 59, 1, {:format=>$.MINUTE_FORMAT});

        var time = splitStoredTime(factories.size());
        var defaults = new Array<Number>[factories.size()];
        if (time != null) {
            var hour = time[0].toNumber();
            if (hour != null) {
                defaults[0] = (factories[0] as NumberFactory).getIndex(hour);
            }

            var min = time[1].toNumber();
            if (min != null) {
                defaults[2] = (factories[2] as NumberFactory).getIndex(min);
            }

            if (defaults.size() == $.FACTORY_COUNT_12_HOUR) {
                defaults[3] = (factories[3] as WordFactory).getIndex(time[2]);
            }
        }

        Picker.initialize({:title=>title, :pattern=>factories, :defaults=>defaults});
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    //! Get the stored time in an array
    //! @param factoryCount Number of factories used to make the time
    //! @return Array with the stored time
    private function splitStoredTime(factoryCount as Number) as Array<String>? {
        var storedValue = Storage.getValue(_storageID);
        var defaults = null;
        var separatorIndex = 0;

        if (storedValue instanceof String) {
            defaults = new Array<String>[factoryCount - 1];

            // Parse the stored time from the format HH:MIN AM|PM
            separatorIndex = storedValue.find(":");
            if (separatorIndex != null) {
                var hour = storedValue.substring(0, separatorIndex);
                if (hour instanceof String) {
                    defaults[0] = hour;

                    if (factoryCount == $.FACTORY_COUNT_24_HOUR) {
                        var min = storedValue.substring(separatorIndex + 1, storedValue.length());
                        if (min instanceof String) {
                            defaults[1] = min;
                        } else {
                            defaults = null;
                        }
                    } else {
                        var spaceIndex = storedValue.find(" ");
                        if (spaceIndex != null) {
                            var min = storedValue.substring(separatorIndex + 1, spaceIndex);
                            var amPm = storedValue.substring(spaceIndex + 1, storedValue.length());
                            if ((min instanceof String) && (amPm instanceof String)) {
                                defaults[1] = min;
                                defaults[2] = amPm;
                            } else {
                                defaults = null;
                            }
                        } else {
                            defaults = null;
                        }
                    }
                } else {
                    defaults = null;
                }
            } else {
                defaults = null;
            }
        }

        return defaults;
    }
}

//! Responds to a time picker selection or cancellation
class TimePickerDelegate extends WatchUi.PickerDelegate {

		var _storageID;
		var _menuItem as WatchUi.MenuItem;

    //! Constructor
    public function initialize(id, menuItem) {
        PickerDelegate.initialize();
				self._storageID = id;
				self._menuItem = menuItem;
    }

    //! Handle a cancel event from the picker
    //! @return true if handled, false otherwise
    public function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    //! Handle a confirm event from the picker
    //! @param values The values chosen in the picker
    //! @return true if handled, false otherwise
    public function onAccept(values as Array) as Boolean {
        var hour = values[0] as Number;
        var min = values[2] as Number;

        var time = hour + ":" + min.format($.MINUTE_FORMAT);

        if (values.size() == $.FACTORY_COUNT_12_HOUR) {
            var dayPart = values[3];
            if (dayPart != null) {
                time += " " + WatchUi.loadResource(dayPart as ResourceId);
            }
        }
        Storage.setValue(_storageID, time);
				_menuItem.setSubLabel(time);

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

}
