import QtQuick
import Quickshell
import qs.services
import qs.components

// One desktop widget, drawn by kind. Placed by its centre, as a fraction of the screen.
Item {
    id: root

    required property var entry
    required property int index

    readonly property var size: Widgets.sizes[entry.kind] ?? [140, 140]
    readonly property string shapeName: entry.shape || Widgets.shapeOf[entry.kind] || "circle"
    width: size[0]
    height: size[1]
    function rebind() {
        x = Qt.binding(() => entry.x * parent.width - width / 2);
        y = Qt.binding(() => entry.y * parent.height - height / 2);
    }
    Component.onCompleted: {
        rebind();
        if (entry.kind === "stats" || entry.kind === "battery") Sys.users++;
    }
    Component.onDestruction: if (entry.kind === "stats" || entry.kind === "battery") Sys.users--

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property color face: Theme.alpha(Theme.surfaceMid, 0.94)

    // picked up a little while it's held or dragged
    scale: drag.drag.active ? 1.06 : drag.containsMouse && !drag.pressed ? 1.02 : 1
    Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
    z: drag.drag.active ? 10 : 0

    // drag it anywhere, any time; right-click to change its shape. (Under the content, so buttons on a
    // widget, like music's play, still get their clicks.)
    MouseArea {
        id: drag
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: drag.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: root
        drag.threshold: 4
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: root.parent.width - root.width
        drag.maximumY: root.parent.height - root.height
        onPressed: m => { if (m.button === Qt.RightButton) Ui.shapeFor = Ui.shapeFor === root.index ? -1 : root.index; else Ui.shapeFor = -1; }
        onReleased: m => {
            if (m.button !== Qt.LeftButton || !drag.drag.active && Math.abs(root.x - (root.entry.x * root.parent.width - root.width / 2)) < 1) return;
            Widgets.move(root.index, (root.x + root.width / 2) / root.parent.width, (root.y + root.height / 2) / root.parent.height);
            root.rebind();
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: ({ clock: clockW, date: dateW, weather: weatherW, battery: batteryW, music: musicW, stats: statsW })[root.entry.kind] ?? null
    }

    // ---- clock: hands in a twelve-sided cookie
    Component {
        id: clockW
        Item {
            MShape { anchors.fill: parent; shape: root.shapeName; color: root.face }
            Repeater {
                model: 12
                Rectangle {
                    required property int index
                    readonly property real a: index * 30 * Math.PI / 180
                    width: index % 3 === 0 ? 5 : 3; height: width; radius: width / 2
                    x: parent.width / 2 + Math.sin(a) * parent.width * 0.33 - width / 2
                    y: parent.height / 2 - Math.cos(a) * parent.height * 0.33 - height / 2
                    color: Theme.alpha(Theme.text, index % 3 === 0 ? 0.6 : 0.3)
                }
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.62
                text: Qt.formatDate(clock.date, "ddd d")
                size: 12
                weight: Font.DemiBold
                color: Theme.textDim
            }
            Hand { len: 0.2; thick: 7; turn: (clock.date.getHours() % 12 + clock.date.getMinutes() / 60) * 30; color: Theme.text }
            Hand { len: 0.29; thick: 5; turn: clock.date.getMinutes() * 6; color: Theme.primary }
            Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: Theme.primary }
        }
    }
    component Hand: Rectangle {
        property real len
        property real thick
        property real turn
        width: thick
        height: parent.height * len + thick / 2
        radius: thick / 2
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height + thick / 2
        transformOrigin: Item.Bottom
        rotation: turn
        antialiasing: true
    }

    // ---- date: an arch
    Component {
        id: dateW
        Item {
            MShape { anchors.fill: parent; shape: root.shapeName; color: root.face }
            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 6
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.date.getDate()
                    size: 50
                    weight: Font.Bold
                    color: Theme.primary
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, "MMMM")
                    size: 14
                    weight: Font.Medium
                    color: Theme.textDim
                }
            }
        }
    }

    // ---- weather: a circle
    Component {
        id: weatherW
        Item {
            MShape { anchors.fill: parent; shape: root.shapeName; color: root.face }
            Column {
                anchors.centerIn: parent
                spacing: 0
                Icon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.icon; size: 30; fill: true; color: Theme.primary }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.ready ? Math.round(Weather.temp) + "°" : "–"
                    size: 36
                    weight: Font.Bold
                }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.words; size: 12; color: Theme.textDim; visible: Weather.ready }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↑" + Math.round(Weather.high) + "°  ↓" + Math.round(Weather.low) + "°"
                    size: 11
                    color: Theme.textDim
                    visible: Weather.ready
                }
            }
        }
    }

    // ---- battery: a sunny shape with a wavy ring
    Component {
        id: batteryW
        Item {
            MShape { anchors.fill: parent; shape: root.shapeName; color: root.face }
            WavyRing {
                anchors.fill: parent
                anchors.margins: 20
                value: Sys.battery
                color: Sys.battery < 0.15 && !Sys.charging ? Theme.error : Theme.primary
                thick: 6
                amp: 1.8
                waves: 9
            }
            Column {
                anchors.centerIn: parent
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(Sys.battery * 100); size: 24; weight: Font.Bold }
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: Sys.charging ? "bolt" : "battery_full"
                    size: 14; fill: true; color: Theme.textDim
                }
            }
        }
    }

    // ---- music: the cover in a pentagon, a play button on it
    Component {
        id: musicW
        // like the rest of the shell: the widget's own face, the cover small in a cookie, a squiggle for
        // how far through the song, and three little buttons
        Item {
            MShape { anchors.fill: parent; shape: root.shapeName; color: root.face }
            Column {
                anchors.centerIn: parent
                width: parent.width * 0.64
                spacing: 3
                ShapedImage {
                    id: cover
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 68; height: 68
                    source: Media.art
                    shape: Media.playing ? "cookie9" : "cookie12"
                    fallback: Theme.primaryBox
                    Icon {
                        anchors.centerIn: parent
                        visible: !cover.ready
                        name: "music_note"; size: 30; fill: true; color: Theme.onPrimaryBox
                    }
                }
                Item { width: 1; height: 2 }
                Txt {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Media.active ? Media.title : "Nothing playing"
                    size: 12.5
                    weight: Font.Bold
                }
                Txt {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Media.artist
                    visible: Media.active && text !== ""
                    size: 10.5
                    color: Theme.textDim
                }
                Wavy {
                    width: parent.width
                    height: 12
                    value: Media.progress
                    thick: 3
                    amp: 2
                    wave: 14
                    track: Theme.alpha(Theme.text, 0.15)
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    Repeater {
                        model: [
                            { icon: "skip_previous", big: false, run: () => Media.previous() },
                            { icon: Media.playing ? "pause" : "play_arrow", big: true, run: () => Media.toggle() },
                            { icon: "skip_next", big: false, run: () => Media.next() }
                        ]
                        MShape {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: modelData.big ? 32 : 26
                            height: width
                            shape: modelData.big ? (Media.playing ? "cookie6" : "circle") : mh.hovered ? "cookie4" : "circle"
                            color: modelData.big ? Theme.primary : mh.hovered ? Theme.surfaceTop : "transparent"
                            Icon {
                                anchors.centerIn: parent
                                name: parent.modelData.icon
                                fill: true
                                size: parent.modelData.big ? 19 : 17
                                color: parent.modelData.big ? Theme.onPrimary : Theme.text
                            }
                            HoverHandler { id: mh }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.run() }
                        }
                    }
                }
            }
        }
    }

    // ---- stats: CPU in a flower
    Component {
        id: statsW
        Item {
            MShape { anchors.fill: parent; shape: root.shapeName; color: root.face }
            WavyRing {
                anchors.fill: parent
                anchors.margins: 30
                value: Sys.cpu
                thick: 5
                amp: 1.4
                waves: 8
                color: Theme.tertiary
            }
            Column {
                anchors.centerIn: parent
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(Sys.cpu * 100) + "%"; size: 17; weight: Font.Bold }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "CPU"; size: 10; color: Theme.textDim }
            }
        }
    }
}
