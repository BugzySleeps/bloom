import QtQuick
import QtQuick.Effects
import qs.services

// A picture cut to one of the shapes
Item {
    id: root

    property alias source: img.source
    property alias shape: mask.shape
    property alias spin: mask.spin
    property color fallback: Theme.primaryBox
    readonly property bool ready: img.status === Image.Ready

    MShape {
        anchors.fill: parent
        shape: mask.shape
        spin: mask.spin
        color: root.fallback
        visible: !root.ready
    }

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        asynchronous: true
        cache: true
        visible: false
    }
    MShape {
        id: mask
        anchors.fill: parent
        color: "black"
        layer.enabled: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
        visible: root.ready
    }
}
