import QtQuick
import Quickshell
import qs.services
import qs.components

// This month; today sits in a little sunny shape. The arrows go to other months.
Card {
    id: root

    SystemClock { id: clock; precision: SystemClock.Hours }
    property int offset: 0
    Connections { target: Ui; function onOpenChanged() { if (Ui.open) root.offset = 0; } }

    readonly property date today: clock.date
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int lead: (shown.getDay() + 6) % 7          // weeks start on Monday
    readonly property int days: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()

    Item {
        id: top
        x: 16; y: 10
        width: parent.width - 32
        height: 28
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(root.shown, root.shown.getFullYear() === root.today.getFullYear() ? "MMMM" : "MMMM yyyy")
            size: 14.5
            weight: Font.Bold
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: ["chevron_left", "chevron_right"]
                MShape {
                    required property string modelData
                    required property int index
                    width: 26; height: 26
                    shape: ah.hovered ? "cookie4" : "circle"
                    color: ah.hovered ? Theme.surfaceTop : "transparent"
                    Icon { anchors.centerIn: parent; name: parent.modelData; size: 18; color: Theme.textDim }
                    HoverHandler { id: ah; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.offset += parent.index === 0 ? -1 : 1 }
                }
            }
        }
    }

    Grid {
        x: 12
        anchors.top: top.bottom
        anchors.topMargin: 2
        columns: 7
        readonly property real cell: (root.width - 24) / 7
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Txt {
                required property string modelData
                width: parent.cell; height: 20
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                size: 11
                weight: Font.Bold
                color: Theme.textDim
            }
        }
        Repeater {
            model: 42
            Item {
                required property int index
                readonly property int day: index - root.lead + 1
                readonly property bool real: day >= 1 && day <= root.days
                readonly property bool isToday: real && root.offset === 0 && day === root.today.getDate()
                width: parent.cell
                height: 21
                visible: index < Math.ceil((root.lead + root.days) / 7) * 7
                MShape {
                    anchors.centerIn: parent
                    width: 24; height: 24
                    visible: parent.isToday
                    shape: "sunny"
                    color: Theme.primary
                }
                Txt {
                    anchors.centerIn: parent
                    text: parent.real ? parent.day : ""
                    size: 12
                    weight: parent.isToday ? Font.Bold : Font.Normal
                    color: parent.isToday ? Theme.onPrimary : (parent.index % 7 > 4 ? Theme.textDim : Theme.text)
                }
            }
        }
    }
}
