import QtQuick

// How a page of the panel comes and goes: out quickly, in a beat later and gently, so two pages are never
// both half-there. `value` goes 0..1.
QtObject {
    id: f
    property bool on: false
    property real value: on ? 1 : 0
    Behavior on value {
        SequentialAnimation {
            PauseAnimation { duration: f.on ? 110 : 0 }
            NumberAnimation {
                target: f
                property: "value"
                duration: f.on ? 260 : 110
                easing.type: Easing.BezierSpline
                easing.bezierCurve: f.on ? [0.05, 0.7, 0.1, 1, 1, 1] : [0.3, 0, 1, 1, 1, 1]
            }
        }
    }
}
