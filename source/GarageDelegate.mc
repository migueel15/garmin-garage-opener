import Toybox.Application;
import Toybox.Attention;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;
using Toybox.Time;
using Toybox.Time.Gregorian;

class GarageDelegate extends WatchUi.BehaviorDelegate {

    private const HOLD_TIME_MS = 1000;

    private var _view as GarageView;
    private var _holdTimer as Timer.Timer = new Timer.Timer();
    private var _holding as Boolean = false;
    private var _requestInProgress as Boolean = false;

    function initialize(view as GarageView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        if (!_view.isInsideButton(event.getCoordinates())) {
            return false;
        }

        return true;
    }

		function onSelectable(event as SelectableEvent) as Boolean {
			var s = event.getInstance();
			if (s.getState() == :stateHighlighted) {
        beginHold(HOLD_TIME_MS);
			}

			if (s.getState() == :stateDefault){
				cancelHold();
			}
			return true;
		}

    function beginHold(delayMs as Number) as Void {
        if (_requestInProgress || _holding) {
            return;
        }

        if (_view.isSleeping()) {
            _view.setState(GARAGE_STATE_SLEEP);
            return;
        }

        _holding = true;
        _view.setState(GARAGE_STATE_HOLDING);
        _holdTimer.start(method(:holdCompleted), delayMs, false);
    }

    function cancelHold() as Void {
        if (!_holding) {
            return;
        }

        _holding = false;
        _holdTimer.stop();
        if (!_requestInProgress) {
            _view.setState(GARAGE_STATE_READY);
        }
    }

    function holdCompleted() as Void {
        if (!_holding || _requestInProgress) {
            return;
        }

        _holding = false;
        pulseShelly();
    }

    function pulseShelly() as Void {
        // Revalidar justo antes de la red evita una carrera si se activa el
        // modo dormir durante la pulsacion de 1,5 segundos.
        if (_view.isSleeping()) {
            _view.setState(GARAGE_STATE_SLEEP);
            return;
        }

				// comprobar que no este en rango
				var isTimeRangeToggled = Application.Storage.getValue("block_sleep_hours") as Boolean;
				var openTime = Application.Storage.getValue("start_time") as String;
				var closeTime = Application.Storage.getValue("end_time") as String;

				System.println(isTimeRangeToggled);
				System.println(openTime);
				System.println(closeTime);

				if (isTimeRangeToggled && isInsideTimeRange(openTime,closeTime)){
          _view.setState(GARAGE_STATE_SLEEP);
					return;
				}

        var url = Application.Properties.getValue("backendUrl");
        var apiToken = Application.Properties.getValue("apiToken");

        if (!(url instanceof Lang.String) || url.length() == 0 ||
            !(apiToken instanceof Lang.String) || apiToken.length() == 0) {
            handleError("Falta URL o token");
            return;
        }

        _requestInProgress = true;
        _view.setState(GARAGE_STATE_SENDING);
        System.println("[GARAGE] makeWebRequest: mandando GET al garaje");

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
        System.println("[GARAGE] Respuesta HTTP: " + responseCode);

        _requestInProgress = false;
        if (responseCode >= 200 && responseCode < 300) {
            _view.setState(GARAGE_STATE_SUCCESS);
            vibrateSuccess();
        } else {
            handleError("HTTP " + responseCode);
        }
    }

    function vibrateSuccess() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 250)]);
        }
    }

    function handleError(message as String) as Void {
        System.println("Error: " + message);
        _requestInProgress = false;
        _view.setState(GARAGE_STATE_ERROR);

        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 180),
                new Attention.VibeProfile(0, 120),
                new Attention.VibeProfile(100, 180),
                new Attention.VibeProfile(0, 120),
                new Attention.VibeProfile(100, 180)
            ]);
        }
    }

		function onMenu() as Boolean {
			toggleMenu(true);
			return true;
		}

		function onActionMenu() as Boolean {
			cancelHold();
			toggleMenu(false);
			return true;
		}

		function toggleMenu(isMenu) {
			var menu = new Rez.Menus.SettingsMenu();
			var idx = menu.findItemById(:block_sleep_hours);
			var toggleItem = menu.getItem(idx) as WatchUi.ToggleMenuItem;

			var isEnabled = Application.Storage.getValue("block_sleep_hours");
		 	if (isEnabled == null) {
				isEnabled = false;
			}

			var start_time = Application.Storage.getValue("start_time");
			var end_time = Application.Storage.getValue("end_time");

			var startTimeItem =  menu.getItem(menu.findItemById(:start_time)) as WatchUi.MenuItem;
			var endTimeItem =  menu.getItem(menu.findItemById(:end_time)) as WatchUi.MenuItem;

			startTimeItem.setSubLabel(start_time);
			endTimeItem.setSubLabel(end_time);

			toggleItem.setEnabled(isEnabled);

			var animation = isMenu ? WatchUi.SLIDE_UP : WatchUi.SLIDE_LEFT;

			WatchUi.pushView(
				menu,
				new SettingsMenuDelegate(),
				animation
			);
		}

function timeToMinutes(time as String) as Number {
    var separator = time.find(":");

    var hour = time.substring(0, separator).toNumber();
    var minute = time.substring(separator + 1, time.length()).toNumber();

    return hour * 60 + minute;
}


function isInsideTimeRange(openTime, closeTime) {
    var now = Gregorian.info(
        Time.now(),
        Time.FORMAT_SHORT
    );

		var start = timeToMinutes(openTime);
		var end = timeToMinutes(closeTime);
    var current = now.hour * 60 + now.min;

    // Ejemplo: 08:00 -> 20:00
    if (start <= end) {
        return current >= start && current < end;
    }

    // Ejemplo: 23:00 -> 08:00
    // El rango cruza medianoche
    return current >= start || current < end;
}
}
