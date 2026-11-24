import QtQuick
import qs.services

// A round quick-settings button: a circle when off, it blooms into a shape when on
Item {
    id: root

    property string icon
    property string label
    property bool on: false
    property string onShape: "cookie6"
    signal clicked()

    implicitWidth: 64
    implicitHeight: 84

    MShape {
        id: blob
        width: 56
        height: 56
        anchors.horizontalCenter: parent.horizontalCenter
        shape: root.on ? root.onShape : hover.hovered ? "square" : "circle"
        color: root.on ? Theme.primary : hover.hovered ? Theme.surfaceTop : Theme.surfaceHigh
        Behavior on color { ColorAnimation { duration: Theme.normal } }
        scale: tap.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutBack } }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: 24
            fill: root.on
            color: root.on ? Theme.onPrimary : Theme.text
        }
    }
    Txt {
        anchors.top: blob.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width + 8
        horizontalAlignment: Text.AlignHCenter
        text: root.label
        size: 11.5
        color: Theme.textDim
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: root.clicked() }
}
