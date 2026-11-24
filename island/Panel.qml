import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.components

// What the island pulls down into: home (music, calendar, stats, quick settings) or style (colours,
// wallpaper, widgets)
Item {
    id: root

    implicitHeight: 72 + (Ui.page === "style" ? style.implicitHeight : home.implicitHeight) + 16
    // the tallest any page gets: the window stays this tall while open, so it never resizes mid-animation
    readonly property real fullHeight: 72 + Math.max(style.implicitHeight, home.implicitHeight) + 16

    // ---- the top line: hello + the buttons
    Item {
        id: head
        x: 22; y: 16
        width: parent.width - 44
        height: 44

        SystemClock { id: clock; precision: SystemClock.Minutes }

        Row {
            spacing: 10
            anchors.verticalCenter: parent.verticalCenter
            opacity: power.open ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            MShape {
                width: 34; height: 34
                anchors.verticalCenter: parent.verticalCenter
                shape: Ui.page === "style" ? "clover4" : "sunny"
                color: Theme.primary
                MouseArea {
                    anchors.fill: parent
                    enabled: Ui.page === "style"
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Ui.page = "home"
                }
                Icon {
                    anchors.centerIn: parent
                    name: Ui.page === "style" ? "arrow_back" : "local_florist"
                    size: 18
                    fill: true
                    color: Theme.onPrimary
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Txt {
                    readonly property int hour: clock.date.getHours()
                    text: Ui.page === "style" ? "Make it yours"
                        : hour < 5 ? "Good night" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
                    size: 17
                    weight: Font.DemiBold
                }
                Txt {
                    text: Ui.page === "style" ? "Colours, wallpaper and what sits on your desktop" : Qt.formatDate(clock.date, "dddd, MMMM d") + (Sys.uptime ? "  ·  up " + Sys.uptime : "")
                    size: 12
                    color: Theme.textDim
                }
            }
        }

        Row {
            id: power
            property bool open: false
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Repeater {
                model: power.open ? [
                    { icon: "lock", shape: "cookie6", run: () => Quickshell.execDetached(["sh", "-c", "~/.config/rice/rice lock"]) },
                    { icon: "logout", shape: "pentagon", run: () => Hyprland.dispatch("hl.dsp.exit()") },
                    { icon: "bedtime", shape: "clover4", run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
                    { icon: "restart_alt", shape: "sunny", run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
                    { icon: "power_settings_new", shape: "flower", run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
                ] : []
                HeadButton {
                    required property var modelData
                    icon: modelData.icon
                    hoverShape: modelData.shape
                    tone: Theme.tertiaryBox
                    ink: Theme.onTertiaryBox
                    onClicked: { Ui.close(); modelData.run(); }
                }
            }
            HeadButton {
                visible: !power.open && Ui.page === "home"
                icon: "apps"
                hoverShape: "cookie6"
                onClicked: Ui.launcher = true
            }
            HeadButton {
                visible: !power.open && Ui.page === "home"
                icon: "palette"
                hoverShape: "clover4"
                onClicked: Ui.page = "style"
            }
            HeadButton {
                icon: power.open ? "close" : "power_settings_new"
                hoverShape: "cookie9"
                onClicked: power.open = !power.open
            }
        }
    }

    component HeadButton: MShape {
        id: hb
        property string icon
        property string hoverShape: "cookie9"
        property color tone: Theme.surfaceHigh
        property color ink: Theme.text
        signal clicked()
        width: 40; height: 40
        shape: hbh.hovered ? hoverShape : "circle"
        color: hbh.hovered ? Theme.primaryBox : tone
        Icon { anchors.centerIn: parent; name: hb.icon; size: 20; color: hbh.hovered ? Theme.onPrimaryBox : hb.ink }
        HoverHandler { id: hbh; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: hb.clicked() }
    }

    // ---- home
    Column {
        id: home
        x: 16
        y: 72
        width: parent.width - 32
        spacing: 12
        PageFade { id: homeFade; on: Ui.page === "home" }
        opacity: homeFade.value
        visible: opacity > 0
        transform: Translate { y: (1 - homeFade.value) * 10 }

        Row {
            spacing: 12
            Player { width: 448; height: 196 }
            Calendar { width: 268; height: 196 }
        }
        Row {
            spacing: 12
            Stats { width: 448; height: 124 }
            Card {
                width: 268; height: 124
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 28
                    spacing: 14
                    Slider {
                        width: parent.width
                        icon: Audio.icon
                        value: Audio.muted ? 0 : Audio.volume
                        onMoved: v => Audio.set(v)
                    }
                    Slider {
                        width: parent.width
                        visible: Bright.present
                        icon: "light_mode"
                        value: Bright.level
                        onMoved: v => Bright.set(v)
                    }
                }
            }
        }
        Card {
            width: parent.width
            height: 108
            Row {
                anchors.centerIn: parent
                spacing: 22
                Toggle { icon: Net.wifi ? "wifi" : "wifi_off"; label: Ui.privacy ? "Wi-Fi" : Net.ssid || "Wi-Fi"; on: Net.wifi; onShape: "cookie6"; onClicked: Net.toggleWifi() }
                Toggle { icon: "bluetooth"; label: Net.btConnected > 0 ? Net.btConnected + " connected" : "Bluetooth"; on: Net.bt; onShape: "clover4"; onClicked: Net.toggleBt() }
                Toggle { icon: Settings.dnd ? "do_not_disturb_on" : "notifications"; label: "Do not disturb"; on: Settings.dnd; onShape: "pentagon"; onClicked: Settings.dnd = !Settings.dnd }
                Toggle { icon: "lyrics"; label: "Lyrics"; on: Settings.lyrics; onShape: "flower"; onClicked: Settings.lyrics = !Settings.lyrics }
                Toggle { icon: "graphic_eq"; label: "Visualizer"; on: Settings.visualizer; onShape: "sunny"; onClicked: Settings.visualizer = !Settings.visualizer }
                Toggle { icon: Settings.dark ? "dark_mode" : "light_mode"; label: Settings.dark ? "Dark" : "Light"; on: Settings.dark; onShape: "cookie9"; onClicked: Settings.dark = !Settings.dark }
            }
        }
        TeamCard {
            width: parent.width
            height: Team.members.length > 0 ? 76 : 52
        }
        Card {
            width: parent.width
            visible: Notifs.count > 0 && !Ui.privacy
            height: Math.min(3, Notifs.count) * 56 + 44
            Txt {
                x: 18; y: 12
                text: Notifs.count + (Notifs.count === 1 ? " notification" : " notifications")
                size: 13
                weight: Font.DemiBold
                color: Theme.textDim
            }
            Txt {
                anchors.right: parent.right
                anchors.rightMargin: 18
                y: 12
                text: "Clear all"
                size: 13
                weight: Font.DemiBold
                color: Theme.primary
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clear() }
            }
            Column {
                y: 38
                width: parent.width
                Repeater {
                    model: Notifs.list.slice(0, 3)
                    Toast {
                        required property var modelData
                        width: parent.width
                        height: 56
                        n: modelData
                        compact: true
                    }
                }
            }
        }
    }

    // ---- style
    Style {
        id: style
        x: 16
        y: 72
        width: parent.width - 32
        PageFade { id: styleFade; on: Ui.page === "style" }
        opacity: styleFade.value
        visible: opacity > 0
        transform: Translate { y: (1 - styleFade.value) * 10 }
    }
}
