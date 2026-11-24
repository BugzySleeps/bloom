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

    // fps 0: as smooth as the screen; otherwise stepped that many times a second (for a squiggle on a big window,
    // like the wallpaper's, where every frame redraws the whole screen)
    property int fps: 0
    NumberAnimation on phase {
        running: root.moving && root.visible && root.fps === 0
        from: 0
        to: Math.PI * 2
        duration: 1400
        loops: Animation.Infinite
    }
    Timer {
        running: root.moving && root.visible && root.fps > 0
        interval: 1000 / Math.max(1, root.fps)
        repeat: true
        onTriggered: root.phase = (root.phase + Math.PI * 2 / (1.4 * root.fps)) % (Math.PI * 2)
    }

    readonly property real cut: Math.max(0, Math.min(1, value)) * width
    readonly property real a: amp * Math.min(1, cut / 20)    // flatten the very start so it grows in
    readonly property real y0: height / 2

    // Two ways of moving. fps 0 (the island): the line is redrawn with its phase every frame, as smooth as can
    // be. fps > 0 (a widget on the wallpaper, where every frame redraws the whole screen): the squiggle is drawn
    // once, a wave longer than needed, and only slides sideways under a clip, so nothing is rebuilt per frame.
    readonly property bool slides: fps > 0
    readonly property real shift: slides ? (phase / (Math.PI * 2)) * wave - wave : 0
    readonly property var wavePts: {
        const out = [], step = 2;
        if (slides) {
            for (let x = 0; x <= cut + wave * 2; x += step)
                out.push(Qt.point(x, y0 + Math.sin(x / wave * Math.PI * 2) * amp));
            return out;
        }
        for (let x = thick / 2; x <= cut; x += step)
            out.push(Qt.point(x, y0 + Math.sin(x / wave * Math.PI * 2 - phase) * a));
        if (out.length < 2) out.push(Qt.point(thick / 2, y0), Qt.point(thick / 2 + 0.1, y0));
        return out;
    }
    function waveY(x) { return y0 + Math.sin((x - shift) / wave * Math.PI * 2) * amp; }

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
    }
    Item {
        x: 0
        width: root.slides ? Math.max(0, root.cut - root.thick / 2) : root.width
        height: root.height
        clip: root.slides
        Shape {
            x: root.shift
            width: root.width + root.wave * 2
            height: root.height
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: root.color
                strokeWidth: root.thick
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: root.wavePts }
            }
        }
    }
    // round ends where the clip cuts the sliding line
    Repeater {
        model: root.slides && root.cut > root.thick ? [root.thick / 2, root.cut - root.thick / 2] : []
        Rectangle {
            required property real modelData
            width: root.thick; height: root.thick; radius: root.thick / 2
            x: modelData - root.thick / 2
            y: root.waveY(modelData) - root.thick / 2
            color: root.color
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
