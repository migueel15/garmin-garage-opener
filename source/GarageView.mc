import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const GARAGE_STATE_READY = 0;
const GARAGE_STATE_HOLDING = 1;
const GARAGE_STATE_SENDING = 2;
const GARAGE_STATE_SUCCESS = 3;
const GARAGE_STATE_ERROR = 4;
const GARAGE_STATE_SLEEP = 5;

class GarageView extends WatchUi.View {

    private var _state as Number = GARAGE_STATE_READY;
    private var _buttonCenterX as Number = 0;
    private var _buttonCenterY as Number = 0;
    private var _buttonRadius as Number = 0;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _buttonCenterX = dc.getWidth() / 2;
        _buttonCenterY = dc.getHeight() / 2;
        _buttonRadius = dc.getWidth() * 34 / 100 + 8;
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;
        var radius = width * 34 / 100;

        dc.setColor(0x071019, 0x071019);
        dc.clear();

        var state = isSleeping() ? GARAGE_STATE_SLEEP : _state;
        var accent = 0x35D0FF;
        var title = "ACTIVAR";
        var subtitle = "";

        if (state == GARAGE_STATE_HOLDING) {
            accent = 0xFFB547;
            title = "ACTIVAR";
            subtitle = "";
        } else if (state == GARAGE_STATE_SENDING) {
            accent = 0x5C8DFF;
            title = "ENVIANDO";
            subtitle = "";
        } else if (state == GARAGE_STATE_SUCCESS) {
            accent = 0x55DB9B;
            title = "ACTIVADA";
            subtitle = "";
        } else if (state == GARAGE_STATE_ERROR) {
            accent = 0xFF667A;
            title = "ERROR";
            subtitle = "";
        } else if (state == GARAGE_STATE_SLEEP) {
            accent = 0x778694;
            title = "MODO DORMIR";
            subtitle = "Control desactivado";
        }

        // Fondo suave para separar el control del borde de la pantalla.
        dc.setColor(0x0A1823, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, width * 47 / 100);
        dc.setColor(0x0D1D29, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, width * 39 / 100);

        dc.setColor(0x8EA2B2, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 9 / 100, Graphics.FONT_XTINY, "MI GARAJE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Sombra, aro de estado y superficie del pulsador.
        dc.setColor(0x03080C, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy + 5, radius + 10);
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, radius + 8);
        dc.setColor(0x102431, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, radius + 2);
        dc.setColor(0x183443, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy - 2, radius - 5);

        drawStateIcon(dc, state, cx, cy - radius / 6, accent, radius);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + radius * 45 / 100, Graphics.FONT_SMALL, title,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x9EB0BD, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 89 / 100, Graphics.FONT_SYSTEM_XTINY, subtitle,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawStateIcon(dc as Dc, state as Number, x as Number,
        y as Number, color as Number, radius as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);

        if (state == GARAGE_STATE_SUCCESS) {
            dc.drawLine(x - radius * 25 / 100, y,
                x - radius * 7 / 100, y + radius * 18 / 100);
            dc.drawLine(x - radius * 7 / 100, y + radius * 18 / 100,
                x + radius * 28 / 100, y - radius * 20 / 100);
        } else if (state == GARAGE_STATE_ERROR) {
            dc.drawLine(x, y - radius * 25 / 100, x, y + radius * 8 / 100);
            dc.fillCircle(x, y + radius * 27 / 100, 3);
        } else if (state == GARAGE_STATE_SLEEP) {
            // Media luna construida con dos circulos superpuestos.
            dc.fillCircle(x, y, radius * 27 / 100);
            dc.setColor(0x183443, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x + radius * 13 / 100,
                y - radius * 10 / 100, radius * 24 / 100);
        } else {
            drawGarageIcon(dc, x, y, radius);
        }
    }

    function drawGarageIcon(dc as Dc, x as Number, y as Number,
        radius as Number) as Void {
        var halfWidth = radius * 30 / 100;
        var top = y - radius * 23 / 100;
        var bottom = y + radius * 28 / 100;

        dc.drawLine(x - halfWidth - 5, top,
            x, top - radius * 17 / 100);
        dc.drawLine(x, top - radius * 17 / 100,
            x + halfWidth + 5, top);
        dc.drawRectangle(x - halfWidth, top,
            halfWidth * 2, bottom - top);
        dc.drawLine(x - halfWidth, y - radius * 5 / 100,
            x + halfWidth, y - radius * 5 / 100);
        dc.drawLine(x - halfWidth, y + radius * 11 / 100,
            x + halfWidth, y + radius * 11 / 100);
    }

    function isSleeping() as Boolean {
        var info = ActivityMonitor.getInfo();
        return (info has :isSleepMode) && info.isSleepMode == true;
    }

    function isInsideButton(coords) as Boolean {
        var dx = coords[0] - _buttonCenterX;
        var dy = coords[1] - _buttonCenterY;
        return (dx * dx + dy * dy) <= (_buttonRadius * _buttonRadius);
    }

    function setState(state as Number) as Void {
        _state = state;
        WatchUi.requestUpdate();
    }
}
