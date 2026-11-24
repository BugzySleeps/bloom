import QtQuick
import QtQuick.Shapes
import qs.services

// A progress line that's a squiggle up to where it's got to, then a plain track (Material's wavy progress).
// It ripples only while `moving`.
Item {
    id: root

    property real value: 0
    property color color: Theme.primary
    property color track: Theme.outlineSoft
    property real thick: 4
    property real amp: 3.2
    property real wave: 22          // px per wave
    property bool moving: false
    property real phase: 0
    property bool seekable: false
    signal seek(real frac)

    implicitHeight: 16

    NumberAnimation on phase {
        running: root.moving && root.visible
        from: 0
        to: Math.PI * 2
        duration: 1400
        loops: Animation.Infinite
    }

    readonly property real cut: Math.max(0, Math.min(1, value)) * width
    readonly property real a: amp * Math.min(1, cut / 20)    // flatten the very start so it grows in
    readonly property var wavePts: {
        const out = [], y0 = height / 2, step = 2;
        for (let x = thick / 2; x <= cut; x += step)
            out.push(Qt.point(x, y0 + Math.sin(x / wave * Math.PI * 2 - phase) * a));
        if (out.length < 2) out.push(Qt.point(thick / 2, y0), Qt.point(thick / 2 + 0.1, y0));
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
            startX: Math.min(root.width - root.thick / 2, root.cut + root.thick * 2.2); startY: root.height / 2
            PathLine { x: root.width - root.thick / 2; y: root.height / 2 }
        }
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thick
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.wavePts }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        enabled: root.seekable
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: m => root.seek(Math.max(0, Math.min(1, (m.x - 6) / root.width)))
    }
}
