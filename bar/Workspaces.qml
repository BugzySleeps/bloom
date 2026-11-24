import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.components

// The workspaces: a dot each, and the one you're on is a shape with its number that slides across and
// turns into a different shape for every workspace
Item {
    id: root

    property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int active: monitor?.activeWorkspace?.id ?? 1
    readonly property var all: Hyprland.workspaces.values.filter(w => w.id > 0)
    readonly property int count: Math.max(5, active, ...all.map(w => w.id))
    readonly property var shapes: ["cookie9", "clover4", "sunny", "pentagon", "flower", "cookie6", "gem", "softBurst", "clover8", "cookie12"]
    readonly property int slot: 28

    implicitWidth: count * slot + 12
    implicitHeight: 40

    function used(id) {
        const w = all.find(w => w.id === id);
        return !!w && (w.toplevels?.values?.length ?? 1) > 0;
    }

    MShape {
        id: blob
        width: 30
        height: 30
        anchors.verticalCenter: parent.verticalCenter
        x: 6 + (root.active - 1) * root.slot + (root.slot - width) / 2
        Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        shape: root.shapes[(root.active - 1) % root.shapes.length]
        color: Theme.primary
        Txt {
            anchors.centerIn: parent
            text: root.active
            size: 13
            weight: Font.Bold
            color: Theme.onPrimary
        }
    }

    Row {
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: root.count
            Item {
                required property int index
                readonly property int wid: index + 1
                width: root.slot
                height: root.slot
                Rectangle {
                    anchors.centerIn: parent
                    readonly property bool busy: root.used(parent.wid)
                    width: busy ? 8 : 6
                    height: width
                    radius: width / 2
                    color: busy ? Theme.textDim : "transparent"
                    border.width: busy ? 0 : 1.5
                    border.color: Theme.outline
                    opacity: parent.wid === root.active ? 0 : hov.hovered ? 1 : 0.85
                    scale: hov.hovered ? 1.4 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.quick } }
                    Behavior on opacity { NumberAnimation { duration: Theme.quick } }
                }
                HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${parent.wid} })`) }
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => {
            const to = Math.max(1, root.active + (e.angleDelta.y > 0 ? -1 : 1));
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${to} })`);
        }
    }
}
