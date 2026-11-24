import QtQuick
import QtQuick.Shapes
import qs.services

// A round gauge: a wavy arc as far as `value`, a plain one for the rest
Item {
    id: root

    property real value: 0
    property color color: Theme.primary
    property color track: Theme.alpha(Theme.text, 0.12)
    property real thick: 5
    property real amp: 2
    property int waves: 10

    readonly property real r: Math.min(width, height) / 2 - thick - amp
    property real v: Math.max(0, Math.min(1, value))
    Behavior on v { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }

    readonly property var arc: {
        const out = [], cx = width / 2, cy = height / 2, n = Math.max(2, Math.round(160 * v));
        for (let i = 0; i <= n; i++) {
            const f = i / 160, a = -Math.PI / 2 + f * Math.PI * 2;
            const rr = r + Math.sin(f * waves * Math.PI * 2) * amp;
            out.push(Qt.point(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr));
        }
        return out;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.track
            strokeWidth: root.thick
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root.r; radiusY: root.r
                startAngle: -90 + root.v * 360 + (root.v > 0 ? 14 : 0)
                sweepAngle: Math.max(0, 360 - root.v * 360 - (root.v > 0 ? 28 : 0))
            }
        }
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thick
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.v > 0.005 ? root.arc : [] }
        }
    }
}
