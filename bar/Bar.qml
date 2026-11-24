import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The bar: two floating pills (workspaces left, the time right). The island in the middle is its own window.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: 52
    exclusiveZone: 52
    color: "transparent"
    WlrLayershell.namespace: "bloom-bar"
    WlrLayershell.layer: WlrLayer.Top

    mask: Region {
        item: left
        Region { item: right }
    }

    component Pill: Rectangle {
        y: 8
        height: 40
        radius: 20
        color: Theme.surfaceMid
        border.width: 1
        border.color: Theme.alpha(Theme.outlineSoft, 0.6)
        Behavior on color { ColorAnimation { duration: Theme.normal } }
        Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    }

    Pill {
        id: left
        x: 10
        width: ws.implicitWidth + 4
        Workspaces {
            id: ws
            anchors.centerIn: parent
            screen: win.modelData
        }
    }

    Pill {
        id: right
        x: win.width - width - 10
        width: clock.implicitWidth + 32
        Row {
            id: clock
            anchors.centerIn: parent
            spacing: 8
            SystemClock { id: now; precision: SystemClock.Minutes }
            Txt {
                id: hm
                text: Qt.formatTime(now.date, "h:mm AP").split(" ")[0]
                size: 15
                weight: Font.DemiBold
            }
            Txt {
                text: Qt.formatTime(now.date, "h:mm AP").split(" ")[1] ?? ""
                size: 11
                weight: Font.Medium
                color: Theme.textDim
                anchors.baseline: hm.baseline
            }
            MShape {
                width: 7; height: 7
                anchors.verticalCenter: parent.verticalCenter
                shape: "sunny"
                color: Theme.primary
            }
            Txt {
                text: Qt.formatDate(now.date, "ddd d")
                size: 14
                weight: Font.Medium
                color: Theme.textDim
            }
        }
        TapHandler { onTapped: Ui.toggle("home") }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
}
