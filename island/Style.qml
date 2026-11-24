import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import qs.services
import qs.components
import qs.desktop

// The few things you can change: the colour, light or dark, the wallpaper, what's on the desktop
Column {
    id: root
    spacing: 12

    component Label: Txt {
        size: 12.5
        weight: Font.Bold
        color: Theme.textDim
        leftPadding: 4
    }

    Card {
        width: parent.width
        height: 128
        Label { x: 16; y: 14; text: "Colour" }
        Row {
            x: 16; y: 44
            spacing: 10
            Repeater {
                model: Theme.presets
                Item {
                    required property var modelData
                    readonly property bool on: Settings.theme === modelData.name
                    width: 54; height: 70
                    Item {
                        width: 50; height: 50
                        anchors.horizontalCenter: parent.horizontalCenter
                        scale: sh.hovered ? 1.08 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutBack } }
                        MShape {
                            anchors.fill: parent
                            visible: !!parent.parent.modelData.seed
                            shape: parent.parent.on ? "sunny" : "cookie9"
                            color: parent.parent.modelData.seed || "transparent"
                        }
                        ShapedImage {
                            anchors.fill: parent
                            visible: !parent.parent.modelData.seed
                            source: "file://" + Theme.wallPath
                            shape: parent.parent.on ? "sunny" : "cookie9"
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: parent.parent.on
                            name: "check"
                            size: 22
                            color: "white"
                            style: Text.Outline
                            styleColor: Theme.alpha("black", 0.25)
                        }
                        HoverHandler { id: sh; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Settings.theme = parent.parent.modelData.name }
                    }
                    Txt {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.modelData.label
                        size: 11
                        color: parent.on ? Theme.text : Theme.textDim
                        weight: parent.on ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }
        // light / dark: a two-part pill
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: 10
            spacing: 4
            Repeater {
                model: [{ dark: false, icon: "light_mode" }, { dark: true, icon: "dark_mode" }]
                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool on: Settings.dark === modelData.dark
                    width: 46; height: 28
                    radius: on ? 14 : 8
                    topLeftRadius: index === 0 || on ? 14 : 6
                    bottomLeftRadius: index === 0 || on ? 14 : 6
                    topRightRadius: index === 1 || on ? 14 : 6
                    bottomRightRadius: index === 1 || on ? 14 : 6
                    color: on ? Theme.primary : Theme.surfaceHigh
                    Behavior on color { ColorAnimation { duration: Theme.normal } }
                    Icon { anchors.centerIn: parent; name: parent.modelData.icon; size: 18; fill: parent.on; color: parent.on ? Theme.onPrimary : Theme.text }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.dark = parent.modelData.dark }
                }
            }
        }
    }

    Card {
        width: parent.width
        height: 140
        Label { x: 16; y: 14; text: "Wallpaper" }
        Txt {
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 14
            text: "From ~/Pictures/wallpapers"
            size: 11.5
            color: Theme.textDim
        }
        FolderListModel {
            id: walls
            folder: "file://" + (Ui.wallFolder || Quickshell.env("HOME") + "/Pictures/wallpapers")
            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
            showDirs: false
            sortField: FolderListModel.Name
        }
        ListView {
            id: list
            x: 12; y: 42
            width: parent.width - 24
            height: 84
            orientation: ListView.Horizontal
            spacing: 10
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: walls.count + 1
            WheelHandler { onWheel: e => list.flick(e.angleDelta.y * 8, 0) }
            delegate: Item {
                required property int index
                readonly property string path: index === 0 ? "" : walls.get(index - 1, "filePath")
                readonly property bool on: Settings.wallpaper === path
                width: 136; height: 84
                Rectangle {
                    anchors.fill: parent
                    radius: parent.on ? 26 : 14
                    color: "transparent"
                    border.width: parent.on ? 3 : 0
                    border.color: Theme.primary
                    Behavior on radius { NumberAnimation { duration: Theme.normal } }
                }
                Item {
                    id: thumb
                    anchors.fill: parent
                    anchors.margins: parent.on ? 6 : 0
                    visible: false
                    Behavior on anchors.margins { NumberAnimation { duration: Theme.normal } }
                    // Bloom's own wallpaper is drawn live, in the theme's colour
                    Loader {
                        anchors.fill: parent
                        active: parent.parent.index === 0
                        sourceComponent: Backdrop {}
                    }
                    Image {
                        anchors.fill: parent
                        visible: parent.parent.index !== 0
                        source: parent.parent.index === 0 ? "" : "file://" + parent.parent.path
                        sourceSize: Qt.size(272, 168)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
                Rectangle {
                    id: thumbMask
                    anchors.fill: thumb
                    radius: parent.on ? 20 : 14
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: thumb
                    source: thumb
                    maskEnabled: true
                    maskSource: thumbMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.wallpaper = parent.path }
            }
        }
    }

    Card {
        width: parent.width
        height: 120
        Label { x: 16; y: 14; text: "On the desktop" }
        Txt {
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 14
            text: "Drag a widget to move it · right-click it to change its shape"
            size: 11.5
            color: Theme.textDim
        }
        Flow {
            x: 16; y: 44
            width: parent.width - 32
            spacing: 8
            Repeater {
                model: [
                    { kind: "clock", label: "Clock", icon: "schedule" },
                    { kind: "date", label: "Date", icon: "calendar_today" },
                    { kind: "weather", label: "Weather", icon: "partly_cloudy_day" },
                    { kind: "battery", label: "Battery", icon: "battery_5_bar" },
                    { kind: "music", label: "Music", icon: "music_note" },
                    { kind: "stats", label: "CPU", icon: "memory" },
                    { kind: "lyrics", label: "Lyrics", icon: "lyrics" },
                    { kind: "visualizer", label: "Visualizer", icon: "graphic_eq" }
                ]
                Chip {
                    required property var modelData
                    icon: modelData.icon
                    label: modelData.label
                    on: modelData.kind === "lyrics" ? Settings.lyrics
                        : modelData.kind === "visualizer" ? Settings.visualizer
                        : Settings.widgets.some(w => w.kind === modelData.kind)
                    onClicked: {
                        const k = modelData.kind;
                        if (k === "lyrics") Settings.lyrics = !Settings.lyrics;
                        else if (k === "visualizer") Settings.visualizer = !Settings.visualizer;
                        else if (on) Settings.setWidgets(Settings.widgets.filter(w => w.kind !== k));
                        else Settings.setWidgets(Settings.widgets.concat([Widgets.place(k)]));
                    }
                }
            }
        }
    }

    component Chip: Rectangle {
        id: c
        property string icon
        property string label
        property bool on
        signal clicked()
        width: chipRow.implicitWidth + 28
        height: 34
        radius: on ? 17 : 10
        color: on ? Theme.primaryBox : "transparent"
        border.width: on ? 0 : 1
        border.color: Theme.outlineSoft
        Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: Theme.normal } }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6
            Icon { name: c.on ? "check" : c.icon; size: 17; fill: c.on; color: c.on ? Theme.onPrimaryBox : Theme.textDim; anchors.verticalCenter: parent.verticalCenter }
            Txt { text: c.label; size: 13; weight: Font.Medium; color: c.on ? Theme.onPrimaryBox : Theme.text; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: c.clicked() }
    }
}
