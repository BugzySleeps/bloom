import QtQuick
import qs.services

// Four little bars that dance to the music (still bars when it's paused or the visualizer is off)
Row {
    id: root
    property bool live: true
    spacing: 2.5
    height: 16
    Repeater {
        model: 4
        Rectangle {
            required property int index
            readonly property var vals: Cava.values
            readonly property real v: root.live && Media.playing && vals.length > 0
                ? Math.max(0.18, vals[[1, 4, 8, 13][index]] ?? 0) : [0.45, 0.8, 0.6, 0.35][index] * (Media.playing ? 1 : 0.5)
            width: 3.5
            height: 4 + v * 12
            anchors.verticalCenter: parent.verticalCenter
            radius: 2
            color: Theme.primary
        }
    }
}
