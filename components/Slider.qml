import QtQuick
import qs.services

// A chunky Material 3 Expressive slider: a filled part, a gap, a thin handle bar, the rest; icon inside
Item {
    id: root

    property real value: 0
    property string icon: ""
    signal moved(real v)

    implicitHeight: 44
    readonly property real v: drag.pressed ? drag.v : value
    readonly property real handleX: 6 + v * (width - 12)

    Rectangle {   // filled
        x: 0
        width: Math.max(height * 0.6, root.handleX - 6)
        height: parent.height
        radius: 14
        color: Theme.primary
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.quick } }
    }
    Rectangle {   // rest
        x: root.handleX + 6
        width: Math.max(0, root.width - x)
        height: parent.height
        radius: 14
        color: Theme.secondaryBox
        Behavior on x { enabled: !drag.pressed; NumberAnimation { duration: Theme.quick } }
    }
    Rectangle {   // handle
        x: root.handleX - 2
        width: 4
        height: parent.height + 8
        y: -4
        radius: 2
        color: Theme.primary
        Behavior on x { enabled: !drag.pressed; NumberAnimation { duration: Theme.quick } }
    }
    Icon {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 20
        fill: true
        color: root.handleX > 44 ? Theme.onPrimary : Theme.text
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        property real v: 0
        cursorShape: Qt.PointingHandCursor
        function at(x) { return Math.max(0, Math.min(1, (x - 6) / (root.width - 12))); }
        onPressed: m => { v = at(m.x); root.moved(v); }
        onPositionChanged: m => { if (pressed) { v = at(m.x); root.moved(v); } }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
