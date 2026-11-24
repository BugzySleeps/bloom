import QtQuick
import qs.services
import qs.components

// The music: the cover cut into a slowly turning cookie, a wavy progress line, the buttons
Card {
    id: root

    color: Theme.secondaryBox
    readonly property bool live: Ui.open && Ui.page === "home"

    // the cookie turns while the music plays (only while you can see it)
    property real turn: 0
    NumberAnimation on turn {
        running: root.live && Media.playing
        from: root.turn
        to: root.turn + 360
        duration: 24000
        loops: Animation.Infinite
    }

    ShapedImage {
        id: art
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        width: 156; height: 156
        source: Media.art
        shape: Media.playing ? "cookie9" : "cookie12"
        spin: root.turn
        fallback: Theme.primaryBox
        Icon {
            anchors.centerIn: parent
            visible: !art.ready
            name: "music_note"
            size: 54
            fill: true
            color: Theme.onPrimaryBox
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Txt {
            width: parent.width
            text: Media.active ? Media.title : "Nothing playing"
            size: 19
            weight: Font.Bold
            color: Theme.onSecondaryBox
        }
        Txt {
            width: parent.width
            text: Media.active ? Media.artist : "Play something and it shows up here"
            size: 13.5
            color: Theme.alpha(Theme.onSecondaryBox, 0.75)
        }
        Item { width: 1; height: 10 }
        Wavy {
            width: parent.width
            height: 18
            value: Media.progress
            moving: root.live && Media.playing
            color: Theme.primary
            track: Theme.alpha(Theme.onSecondaryBox, 0.2)
            seekable: Media.active
            onSeek: f => Media.seek(f)
        }
        Item {
            width: parent.width
            height: 16
            Txt { text: Media.time(Media.position); size: 11; color: Theme.alpha(Theme.onSecondaryBox, 0.7) }
            Txt { anchors.right: parent.right; text: Media.time(Media.length); size: 11; color: Theme.alpha(Theme.onSecondaryBox, 0.7) }
        }
        Item { width: 1; height: 6 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            Btn { icon: "skip_previous"; onClicked: Media.previous() }
            Btn {
                big: true
                icon: Media.playing ? "pause" : "play_arrow"
                restShape: Media.playing ? "square" : "cookie6"
                onClicked: Media.toggle()
            }
            Btn { icon: "skip_next"; onClicked: Media.next() }
        }
    }

    component Btn: MShape {
        id: b
        property string icon
        property bool big: false
        property string restShape: "circle"
        signal clicked()
        width: big ? 54 : 42
        height: width
        anchors.verticalCenter: parent.verticalCenter
        shape: bh.hovered && !big ? "cookie4" : restShape
        color: big ? Theme.primary : bh.hovered ? Theme.alpha(Theme.onSecondaryBox, 0.12) : "transparent"
        scale: bt.pressed ? 0.88 : 1
        Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutBack } }
        Icon {
            anchors.centerIn: parent
            name: b.icon
            fill: true
            size: b.big ? 28 : 24
            color: b.big ? Theme.onPrimary : Theme.onSecondaryBox
        }
        HoverHandler { id: bh; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: bt; onTapped: b.clicked() }
    }
}
