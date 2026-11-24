import QtQuick
import Quickshell
import qs.services
import qs.components

// A notification inside the island (when it drops in, and in the panel's list)
Item {
    id: root

    property var n: null
    property bool compact: false
    readonly property string img: n ? (n.image || "") : ""
    readonly property string appIcon: n ? (n.appIcon || "") : ""

    // clicking the notification itself runs its default action if it has one, else opens the panel
    MouseArea {
        anchors.fill: parent
        enabled: !!root.n
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const a = root.n.actions.find(a => a.identifier === "default") ?? root.n.actions[0];
            Ui.peeking = "";
            if (a) a.invoke();
            else if (!root.compact) Ui.toggle("home");
        }
    }

    MShape {
        id: badge
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: root.compact ? 36 : 48
        height: width
        shape: "cookie9"
        color: Theme.tertiaryBox
        Icon {
            anchors.centerIn: parent
            visible: !pic.ready && !icon.visible
            name: "notifications"
            fill: true
            color: Theme.onTertiaryBox
            size: parent.width * 0.48
        }
        Image {
            id: icon
            anchors.centerIn: parent
            width: parent.width * 0.55
            height: width
            sourceSize: Qt.size(width * 2, height * 2)
            visible: !pic.ready && status === Image.Ready
            source: root.appIcon === "" ? "" : root.appIcon.startsWith("/") || root.appIcon.includes("://") ? root.appIcon : Quickshell.iconPath(root.appIcon, true)
        }
    }
    ShapedImage {
        id: pic
        anchors.fill: badge
        source: root.img
        shape: "cookie9"
        visible: ready
        fallback: "transparent"
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 12
        anchors.right: close.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Txt {
            width: parent.width
            text: root.n ? root.n.appName : ""
            size: 11
            color: Theme.textDim
            visible: text !== "" && !root.compact
        }
        Txt {
            width: parent.width
            text: root.n ? root.n.summary : ""
            size: 14
            weight: Font.DemiBold
        }
        Txt {
            width: parent.width
            text: root.n ? root.n.body.replace(/<[^>]*>/g, "") : ""
            size: 12.5
            color: Theme.textDim
            visible: text !== ""
            maximumLineCount: 1
        }
    }

    MShape {
        id: close
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 28; height: 28
        shape: closeHov.hovered ? "cookie4" : "circle"
        color: closeHov.hovered ? Theme.surfaceTop : "transparent"
        Icon { anchors.centerIn: parent; name: "close"; size: 16; color: Theme.textDim }
        HoverHandler { id: closeHov }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { Notifs.dismiss(root.n); Ui.peeking = ""; }
        }
    }

}
