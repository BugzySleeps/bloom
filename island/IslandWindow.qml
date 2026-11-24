import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// The dynamic island: a pill in the middle of the top that shows what's going on (the music, the volume,
// a notification), and pulls down into the panel when you click it
PanelWindow {
    id: win

    required property var modelData
    screen: modelData
    readonly property bool main: modelData === Quickshell.screens[0]

    anchors.top: true
    implicitWidth: 780
    // tall only while the panel is open (so the rest of the time there's little to repaint)
    property bool tall: false
    implicitHeight: tall ? Math.min(screen.height - 20, panel.fullHeight + 30) : 110
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "bloom-island"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: Ui.open && main ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool grabbing: false
    Timer { id: grabLater; interval: 120; onTriggered: win.grabbing = Ui.open }
    color: "transparent"
    visible: main

    mask: Region { item: island }

    Connections {
        target: Ui
        function onOpenChanged() {
            win.morphing = true;
            morphDone.restart();
            win.grabbing = false;
            if (Ui.open) { win.tall = true; grabLater.restart(); }
            else shrink.restart();
        }
        function onPageChanged() {
            if (!Ui.open) return;
            win.grabbing = false;
            grabLater.restart();
        }
    }
    Timer { id: shrink; interval: 420; onTriggered: if (!Ui.open) win.tall = false }
    property bool morphing: false
    Timer { id: morphDone; interval: 560; onTriggered: win.morphing = false }

    HyprlandFocusGrab {
        windows: [win]
        active: win.grabbing && win.main
        onCleared: if (win.grabbing) Ui.close()
    }

    // what the closed island shows, most important first
    readonly property string mode: Ui.open ? "open"
        : Ui.peeking === "notif" && Notifs.shown ? "notif"
        : Ui.peeking === "volume" || Ui.peeking === "brightness" ? "level"
        : Media.active ? "music"
        : "rest"

    readonly property size want: {
        switch (mode) {
        case "open": return Qt.size(760, panel.implicitHeight);
        case "notif": return Qt.size(440, 78);
        case "level": return Qt.size(300, 40);
        case "music": return Qt.size(Math.min(360, musicRow.implicitWidth + 28), 40);
        default: return Qt.size(restRow.implicitWidth + 32, 40);
        }
    }

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        width: win.want.width
        height: win.want.height
        radius: win.mode === "open" ? 32 : Math.min(height / 2, 26)
        color: win.mode === "open" ? Theme.surfaceLow : Theme.surfaceMid
        border.width: 1
        border.color: Theme.alpha(Theme.outlineSoft, 0.6)
        clip: true

        // Material's motion curves, no bounce: opening decelerates hard into place ("emphasized"), closing and
        // the small changes (music, volume, a notification) use the standard curve
        readonly property bool opening: win.mode === "open"
        readonly property int dur: opening ? 480 : 360
        readonly property var curve: opening ? [0.05, 0.7, 0.1, 1, 1, 1] : [0.2, 0, 0, 1, 1, 1]
        Behavior on width { NumberAnimation { duration: island.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: island.curve } }
        Behavior on height { NumberAnimation { duration: island.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: island.curve } }
        Behavior on radius { NumberAnimation { duration: island.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: island.curve } }
        Behavior on color { ColorAnimation { duration: Theme.normal } }

        Keys.onEscapePressed: Ui.close()
        focus: Ui.open

        HoverHandler { id: hov; cursorShape: win.mode === "open" ? Qt.ArrowCursor : Qt.PointingHandCursor }
        TapHandler {
            enabled: win.mode !== "open" && win.mode !== "notif"
            onTapped: Ui.toggle("home")
        }
        scale: hov.hovered && win.mode !== "open" ? 1.03 : 1
        Behavior on scale { NumberAnimation { duration: Theme.quick } }

        // ---- closed: nothing much going on
        Row {
            id: restRow
            anchors.centerIn: parent
            spacing: 10
            opacity: win.mode === "rest" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            MShape {
                width: 18; height: 18
                anchors.verticalCenter: parent.verticalCenter
                shape: hov.hovered ? "flower" : "cookie9"
                color: Theme.primary
            }
            Row {
                spacing: 4
                visible: Weather.ready
                anchors.verticalCenter: parent.verticalCenter
                Icon { name: Weather.icon; size: 18; fill: true; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                Txt { text: Math.round(Weather.temp) + "°"; size: 14; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                spacing: 3
                visible: Sys.hasBattery
                anchors.verticalCenter: parent.verticalCenter
                Icon {
                    name: Sys.charging ? "battery_charging_full" : "battery_" + Math.min(6, Math.floor(Sys.battery * 7)) + "_bar"
                    size: 17; fill: true; rotation: 90; color: Sys.battery < 0.15 && !Sys.charging ? Theme.error : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
                Txt { text: Math.round(Sys.battery * 100) + "%"; size: 13.5; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle {
                visible: Notifs.count > 0 && !Ui.privacy
                width: 7; height: 7; radius: 4
                color: Theme.tertiary
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ---- closed: music playing
        Row {
            id: musicRow
            anchors.verticalCenter: parent.verticalCenter
            x: 8
            spacing: 10
            opacity: win.mode === "music" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            ShapedImage {
                width: 28; height: 28
                anchors.verticalCenter: parent.verticalCenter
                source: Media.art
                shape: "cookie7"
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 230)
                text: Media.title
                size: 13.5
                weight: Font.Medium
            }
            Eq {
                anchors.verticalCenter: parent.verticalCenter
                live: win.mode === "music"
            }
        }

        // ---- closed: volume or brightness just changed
        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 14
            spacing: 12
            opacity: win.mode === "level" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            readonly property bool vol: Ui.peeking === "volume"
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: parent.vol ? Audio.icon : "light_mode"
                fill: true
                size: 20
            }
            Wavy {
                anchors.verticalCenter: parent.verticalCenter
                width: 200
                value: parent.vol ? (Audio.muted ? 0 : Audio.volume) : Bright.level
                Behavior on value { NumberAnimation { duration: Theme.quick } }
                amp: 2.6
                wave: 16
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round((parent.vol ? (Audio.muted ? 0 : Audio.volume) : Bright.level) * 100)
                size: 13
                weight: Font.Medium
                color: Theme.textDim
            }
        }

        // ---- closed: a notification dropping in
        Toast {
            anchors.fill: parent
            n: Notifs.shown
            opacity: win.mode === "notif" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.quick } }
        }

        // ---- open
        // the panel stays still on screen while the island opens round it (centred, not pinned to the
        // moving left edge), fades in just after the island starts growing and out first when it closes.
        // Drawn as one cached picture, so each frame of the opening only moves a texture.
        Panel {
            id: panel
            width: 760
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.mode === "open" ? 0 : -14
            opacity: win.mode === "open" ? 1 : 0
            visible: opacity > 0
            // cached as one picture only while the island opens or closes (a page change redraws its
            // contents anyway, so a cache there is just extra work)
            layer.enabled: visible && win.morphing
            layer.smooth: true
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: win.mode === "open" ? 110 : 0 }
                    NumberAnimation { target: panel; property: "opacity"; duration: win.mode === "open" ? 300 : 130; easing.type: Easing.OutCubic }
                }
            }
            Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
        }
    }
}
