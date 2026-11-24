import QtQuick
import QtQuick.Shapes
import qs.services
import "Shapes.js" as S

// One of the Material-style shapes (see Shapes.js). Change `shape` and it morphs into the new one.
Item {
    id: root

    property string shape: "circle"
    property color color: Theme.primary
    property color border: "transparent"
    property real borderWidth: 0
    property int duration: Theme.slow
    property real spin: 0            // turns the outline only (what's inside stays upright)

    property var from: S.points(shape)
    property var to: from
    property real t: 1
    property string _last: shape

    onShapeChanged: {
        if (shape === _last) return;
        from = mix();
        to = S.points(shape);
        _last = shape;
        t = 0;
        anim.restart();
    }
    NumberAnimation {
        id: anim
        target: root
        property: "t"
        from: 0
        to: 1
        duration: root.duration
        easing.type: Easing.OutBack
        easing.overshoot: 1.1
    }

    function mix() {
        if (t >= 1) return to;
        const out = [];
        for (let i = 0; i < to.length; i++)
            out.push([from[i][0] + (to[i][0] - from[i][0]) * t, from[i][1] + (to[i][1] - from[i][1]) * t]);
        return out;
    }

    readonly property var path: {
        const p = t >= 1 ? to : mix();
        const hw = width / 2, hh = height / 2, out = [];
        const a = spin * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
        for (let i = 0; i < p.length; i++) {
            const x = p[i][0] * c - p[i][1] * s, y = p[i][0] * s + p[i][1] * c;
            out.push(Qt.point(hw + x * hw, hh + y * hh));
        }
        out.push(out[0]);
        return out;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.color
            strokeColor: root.border
            strokeWidth: root.borderWidth
            PathPolyline { path: root.path }
        }
    }
}
