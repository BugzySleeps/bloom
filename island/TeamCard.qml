import QtQuick
import qs.services
import qs.components

// Your characters in a row, just standing there. They bob a touch while the panel is open
// (out of step, so it's a crowd, not a dance); they don't react to the mouse.
Card {
    id: root

    readonly property bool live: Ui.open && Ui.page === "home"

    Txt {
        anchors.centerIn: parent
        visible: Team.members.length === 0
        text: "Put character pictures in ~/.local/share/bloom/team"
        size: 13
        color: Theme.textDim
    }

    Row {
        anchors.centerIn: parent
        spacing: Math.max(4, Math.min(34, (root.width - 40 - Team.members.length * 64) / Math.max(1, Team.members.length - 1)))
        Repeater {
            model: Team.members
            Item {
                id: m
                required property var modelData
                required property int index
                width: 64
                height: root.height - 16

                property real bob: 0
                SequentialAnimation on bob {
                    running: root.live
                    loops: Animation.Infinite
                    PauseAnimation { duration: m.index * 260 }
                    NumberAnimation { from: 0; to: -3; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { from: -3; to: 0; duration: 900; easing.type: Easing.InOutSine }
                }

                Loader {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2 - m.bob
                    width: 54; height: 54
                    sourceComponent: m.modelData.gif ? gifPic : stillPic
                }
                Component {
                    id: stillPic
                    Image {
                        source: "file://" + m.modelData.path
                        sourceSize: Qt.size(108, 108)
                        fillMode: Image.PreserveAspectFit
                        verticalAlignment: Image.AlignBottom
                        smooth: true
                        mipmap: true
                    }
                }
                Component {
                    id: gifPic
                    AnimatedImage {
                        source: "file://" + m.modelData.path
                        fillMode: Image.PreserveAspectFit
                        verticalAlignment: Image.AlignBottom
                        playing: root.live
                    }
                }

            }
        }
    }
}
