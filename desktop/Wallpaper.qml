import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The wallpaper (Bloom's own, drawn in the theme's colour, or a picture that fades in) and the widgets on it
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "bloom-wallpaper"
    color: Theme.surface

    readonly property bool own: Settings.wallpaper === ""

    Backdrop {
        anchors.fill: parent
        opacity: win.own ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
    }

    // two pictures: the new one fades in over the old
    property bool flip: false
    readonly property string src: win.own ? "" : "file://" + Settings.wallpaper
    component Pic: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(win.width, win.height)
        asynchronous: true
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
    }
    Pic { id: a; opacity: !win.own && !win.flip ? 1 : 0 }
    Pic { id: b; opacity: !win.own && win.flip ? 1 : 0 }
    Component.onCompleted: if (src) a.source = src
    onSrcChanged: if (src) (win.flip ? a : b).source = src
    Connections {
        target: a
        function onStatusChanged() { if (a.status === Image.Ready && a.source.toString() === win.src) win.flip = false; }
    }
    Connections {
        target: b
        function onStatusChanged() { if (b.status === Image.Ready && b.source.toString() === win.src) win.flip = true; }
    }

    // a click on the bare desktop puts the shape picker away
    MouseArea {
        anchors.fill: parent
        enabled: Ui.shapeFor >= 0
        onPressed: Ui.shapeFor = -1
    }

    Item {
        id: desk
        anchors.fill: parent
        Repeater {
            id: widgets
            // by count, so moving one doesn't rebuild them all
            model: Settings.widgets.length
            Widget {
                entry: Settings.widgets[index] ?? { kind: "", x: 0, y: 0 }
            }
        }
    }

    // ---- the shape picker, next to the widget you right-clicked
    Rectangle {
        id: picker
        readonly property Item target: Ui.shapeFor >= 0 ? widgets.itemAt(Ui.shapeFor) : null
        readonly property string current: target ? target.shapeName : ""
        visible: opacity > 0
        opacity: target ? 1 : 0
        scale: target ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: Theme.quick } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
        width: 5 * 46 + 4 * 6 + 24
        height: grid.implicitHeight + 24
        radius: 26
        color: Theme.surfaceLow
        border.width: 1
        border.color: Theme.alpha(Theme.outlineSoft, 0.6)
        property real tx: 0
        property real ty: 0
        onTargetChanged: if (target) {
            // beside it, on whichever side has room
            const right = target.x + target.width + 12;
            tx = right + width < win.width ? right : target.x - width - 12;
            ty = Math.max(12, Math.min(win.height - height - 12, target.y + target.height / 2 - height / 2));
        }
        x: tx
        y: ty

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: 5
            spacing: 6
            Repeater {
                model: Widgets.shapes
                MShape {
                    required property string modelData
                    width: 46; height: 46
                    shape: modelData
                    color: modelData === picker.current ? Theme.primary : ph.hovered ? Theme.primaryBox : Theme.surfaceHigh
                    scale: ph.hovered ? 1.1 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutBack } }
                    HoverHandler { id: ph; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Widgets.setShape(Ui.shapeFor, parent.modelData) }
                }
            }
        }
    }
}
