import Toybox.Application;
import Toybox.Attention;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class GarageDelegate extends WatchUi.BehaviorDelegate {

    private const HOLD_TIME_MS = 1500;
    // Garmin genera onHold tras aproximadamente un segundo de pulsacion.
    private const TOUCH_HOLD_REMAINDER_MS = 500;

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

    function onHold(event as WatchUi.ClickEvent) as Lang.Boolean {
        if (!_view.isInsideButton(event.getCoordinates())) {
            return false;
        }

        beginHold(TOUCH_HOLD_REMAINDER_MS);
        return true;
    }

    function onRelease(event as WatchUi.ClickEvent) as Lang.Boolean {
        cancelHold();
        return true;
    }

    function onKeyPressed(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() != WatchUi.KEY_ENTER) {
            return false;
        }

        beginHold(HOLD_TIME_MS);
        return true;
    }

    function onKeyReleased(event as WatchUi.KeyEvent) as Lang.Boolean {
        if (event.getKey() != WatchUi.KEY_ENTER) {
            return false;
        }

        cancelHold();
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
}
