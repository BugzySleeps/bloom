import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services
import qs.components

// Bloom's lock screen (after Nebula's space lock, written fresh): a night sky in the theme's colour, the clock,
// and in the middle a bloom: the cover of what's playing cut into a turning cookie, with a ring of petals that
// moves with the music. Little shapes orbit it with the weather, battery, date and notifications. Type your
// password anywhere: every letter is a different shape.
Item {
    id: root

    property bool preview: false
    readonly property real cx: width / 2
    readonly property real cy: height * 0.5

    // ---- coming in: a slow bloom at login, quicker otherwise
    property real intro: 0
    NumberAnimation on intro { from: 0; to: 1; duration: Lock.boot ? 1600 : 700; easing.type: Easing.OutCubic; running: true }
    function at(start, len) { return Math.max(0, Math.min(1, (intro - start) / len)); }

    // one clock for everything that drifts (only runs while this is on screen)
    property real t: 0
    FrameAnimation {
        // only while the lock (or its preview) is actually up: the session lock keeps its screen built in the
        // background, and a clock ticking every frame there cost ~30% CPU while unlocked
        running: root.visible && (Lock.locked || Lock.preview)
        onTriggered: root.t += frameTime
    }

    // ---- the sky
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.tone(Theme.h, Theme.s * 0.55, 0.045) }
            GradientStop { position: 0.6; color: Theme.tone(Theme.h, Theme.s * 0.7, 0.09) }
            GradientStop { position: 1; color: Theme.tone(Theme.h, Theme.s * 0.9, 0.16) }
        }
    }
    // a glow behind the bloom
    Rectangle {
        x: root.cx - width / 2
        y: root.cy - height / 2
        width: 900; height: 900
        radius: 450
        opacity: 0.55 * root.at(0, 0.6)
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Theme.alpha(Theme.primary, 0.16) }
            GradientStop { position: 1; color: "transparent" }
        }
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 64 }
    }
    // stars, drawn once
    Canvas {
        anchors.fill: parent
        opacity: root.at(0.1, 0.6)
        property color ink: Theme.tone(Theme.h, Theme.s * 0.4, 0.92)
        onInkChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const g = getContext("2d");
            g.reset();
            let seed = 7;
            const rnd = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647; };
            for (let i = 0; i < 170; i++) {
                const x = rnd() * width, y = rnd() * height, r = rnd() < 0.08 ? 1.6 : 0.5 + rnd() * 0.8;
                g.globalAlpha = 0.15 + rnd() * 0.6;
                g.fillStyle = ink;
                g.beginPath();
                g.arc(x, y, r, 0, Math.PI * 2);
                g.fill();
            }
        }
    }
    // two big soft shapes drifting far behind
    Repeater {
        model: [
            { shape: "clover8", x: 0.12, y: 0.78, r: 260, speed: 3 },
            { shape: "cookie9", x: 0.9, y: 0.2, r: 220, speed: -2 }
        ]
        MShape {
            required property var modelData
            width: modelData.r * 2; height: width
            x: root.width * modelData.x - width / 2 + Math.sin(root.t * 0.05 * modelData.speed) * 30
            y: root.height * modelData.y - height / 2 + Math.cos(root.t * 0.04 * modelData.speed) * 20
            shape: modelData.shape
            spin: root.t * modelData.speed
            color: Theme.alpha(Theme.primary, 0.06)
            opacity: root.at(0, 0.8)
        }
    }

    // ---- the clock
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 48 + (1 - root.at(0.2, 0.5)) * -30
        opacity: root.at(0.2, 0.5)
        spacing: -6
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Txt {
                id: hm
                text: Qt.formatTime(clock.date, "h:mm AP").split(" ")[0]
                size: 112
                weight: Font.Bold
                wdth: 88
                color: Theme.tone(Theme.h, Theme.s * 0.4, 0.93)
            }
            Txt {
                anchors.baseline: hm.baseline
                text: Qt.formatTime(clock.date, "h:mm AP").split(" ")[1] ?? ""
                size: 26
                weight: Font.DemiBold
                color: Theme.primary
            }
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "dddd, MMMM d")
            size: 19
            weight: Font.Medium
            color: Theme.alpha(Theme.tone(Theme.h, Theme.s * 0.4, 0.9), 0.7)
        }
    }

    // ---- the bloom
    Item {
        id: bloom
        z: 2          // planets pass behind it (z 1) and in front of it (z 3); the sky stays at 0
        x: root.cx - width / 2
        y: root.cy - height / 2 + 30
        width: 340; height: 340
        scale: 0.6 + 0.4 * root.at(0.15, 0.6)
        opacity: root.at(0.15, 0.5)

        // petals: a ring that opens with the music (gently breathing when there's none)
        readonly property var vals: Lock.locked || Lock.preview ? Cava.values : []   // (not while it's hidden)
        Repeater {
            model: 24
            Rectangle {
                required property int index
                readonly property real a: index / 24 * Math.PI * 2 + root.t * 0.08
                readonly property real v: bloom.vals.length ? bloom.vals[Math.abs(index - 12) % Cava.bars] ?? 0 : 0.15 + 0.1 * Math.sin(root.t * 1.2 + index)
                readonly property real len: 18 + v * 46
                width: 10
                height: len
                radius: 5
                x: bloom.width / 2 + Math.cos(a) * (128 + len / 2) - width / 2
                y: bloom.height / 2 + Math.sin(a) * (128 + len / 2) - height / 2
                rotation: a * 180 / Math.PI + 90
                color: Theme.alpha(index % 2 ? Theme.tertiary : Theme.primary, 0.35 + v * 0.5)
            }
        }
        // the middle: the cover, or a flower with a lock when nothing plays
        ShapedImage {
            id: cover
            anchors.centerIn: parent
            width: 220; height: 220
            visible: Media.active
            source: Media.art
            shape: "cookie12"
            spin: root.t * (Media.playing ? 6 : 0)
            fallback: Theme.primaryBox
        }
        MShape {
            anchors.centerIn: parent
            width: 220; height: 220
            visible: !Media.active || !cover.ready
            shape: "flower"
            spin: root.t * 4
            color: Theme.primaryBox
            Icon {
                anchors.centerIn: parent
                name: Lock.checking ? "hourglass_top" : "lock"
                fill: true
                size: 64
                color: Theme.onPrimaryBox
            }
        }
    }

    // the song and its buttons, under the bloom
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: bloom.y + bloom.height - 6
        spacing: 2
        visible: Media.active
        opacity: root.at(0.35, 0.5)
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, 420)
            text: Media.title
            size: 17
            weight: Font.Bold
            color: Theme.tone(Theme.h, Theme.s * 0.4, 0.93)
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, 420)
            text: Media.artist
            size: 13
            color: Theme.alpha(Theme.tone(Theme.h, Theme.s * 0.4, 0.9), 0.65)
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            topPadding: 6
            Repeater {
                model: [
                    { icon: "skip_previous", run: () => Media.previous() },
                    { icon: Media.playing ? "pause" : "play_arrow", run: () => Media.toggle(), big: true },
                    { icon: "skip_next", run: () => Media.next() }
                ]
                MShape {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: modelData.big ? 44 : 34; height: width
                    shape: modelData.big ? (Media.playing ? "cookie6" : "circle") : bh.hovered ? "cookie4" : "circle"
                    color: modelData.big ? Theme.primary : bh.hovered ? Theme.alpha(Theme.primary, 0.2) : "transparent"
                    Icon {
                        anchors.centerIn: parent
                        name: parent.modelData.icon
                        fill: true
                        size: parent.modelData.big ? 24 : 20
                        color: parent.modelData.big ? Theme.onPrimary : Theme.tone(Theme.h, Theme.s * 0.4, 0.9)
                    }
                    HoverHandler { id: bh; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: parent.modelData.run() }
                }
            }
        }
    }

    // ---- the orbit: little shapes going round the bloom, smaller and dimmer when they're behind it
    Repeater {
        model: [
            { shape: "sunny", icon: Weather.icon, text: Weather.ready ? Math.round(Weather.temp) + "°" : "" },
            { shape: "pentagon", icon: Sys.charging ? "bolt" : "battery_full", text: Sys.hasBattery ? Math.round(Sys.battery * 100) + "%" : "" },
            { shape: "clover4", icon: "notifications", text: Notifs.count > 0 ? String(Notifs.count) : "0" },
            { shape: "cookie6", icon: "calendar_today", text: String(clock.date.getDate()) }
        ]
        MShape {
            id: moon
            required property var modelData
            required property int index
            visible: modelData.text !== ""
            readonly property real a: root.t * 0.16 + index * Math.PI / 2
            readonly property real depth: (Math.sin(a) + 1) / 2          // 0 at the back, 1 in front
            readonly property real out: root.at(0.3 + index * 0.08, 0.5)
            // a flat ellipse, tilted a little, like a ring seen from slightly above
            readonly property real ox: Math.cos(a) * 330 * out
            readonly property real oy: Math.sin(a) * 105 * out
            readonly property real tilt: -0.22
            width: 70; height: 70
            x: root.cx + ox * Math.cos(tilt) - oy * Math.sin(tilt) - width / 2
            y: root.cy + 30 + ox * Math.sin(tilt) + oy * Math.cos(tilt) - height / 2
            // it changes sides out at the far left and right, where it's clear of the bloom, so the swap can't be seen
            z: depth >= 0.5 ? 3 : 1
            // nearer is bigger and brighter, smoothly all the way round
            scale: (0.62 + 0.5 * depth) * out
            opacity: (0.35 + 0.65 * depth) * out
            shape: modelData.shape
            spin: root.t * 10 * (index % 2 ? -1 : 1)
            color: Theme.surfaceHigh
            Column {
                anchors.centerIn: parent
                Icon { anchors.horizontalCenter: parent.horizontalCenter; name: moon.modelData.icon; size: 20; fill: true; color: Theme.primary }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: moon.modelData.text; size: 13; weight: Font.Bold }
            }
        }
    }

    // ---- the password
    Item {
        id: entry
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - 120
        width: 340
        height: 56
        opacity: root.at(0.45, 0.5)

        property real shake: 0
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: entry; property: "shake"; to: -14; duration: 50 }
            NumberAnimation { target: entry; property: "shake"; to: 12; duration: 70 }
            NumberAnimation { target: entry; property: "shake"; to: -8; duration: 70 }
            NumberAnimation { target: entry; property: "shake"; to: 5; duration: 70 }
            NumberAnimation { target: entry; property: "shake"; to: 0; duration: 80 }
        }
        Connections { target: Lock; function onWrong() { shakeAnim.restart(); } }
        transform: Translate { x: entry.shake }

        Rectangle {
            anchors.fill: parent
            radius: 28
            color: Theme.alpha(Theme.surfaceHigh, 0.85)
            border.width: 2
            border.color: Lock.message !== "" ? Theme.error : Lock.password !== "" ? Theme.primary : "transparent"
            Behavior on border.color { ColorAnimation { duration: Theme.quick } }
        }
        MShape {
            x: 9
            anchors.verticalCenter: parent.verticalCenter
            width: 38; height: 38
            shape: Lock.checking ? "softBurst" : "cookie9"
            spin: Lock.checking ? root.t * 180 : 0
            color: Theme.primary
            Icon { anchors.centerIn: parent; name: "person"; size: 20; fill: true; color: Theme.onPrimary; visible: !Lock.checking }
        }
        // the letters, each its own little shape
        Row {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 14
            spacing: 5
            Repeater {
                model: Math.min(Lock.password.length, 16)
                MShape {
                    required property int index
                    width: 14; height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    shape: ["circle", "cookie6", "clover4", "sunny", "pentagon", "flower", "gem", "cookie9"][index % 8]
                    color: Theme.primary
                    scale: 0
                    Component.onCompleted: scale = 1
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 3 } }
                }
            }
        }
        Txt {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 14
            visible: Lock.password === ""
            text: Lock.message !== "" ? Lock.message : "Type your password"
            size: 14
            color: Lock.message !== "" ? Theme.error : Theme.textDim
        }
    }
    Txt {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: entry.bottom
        anchors.topMargin: 12
        text: Ui.privacy ? "" : Quickshell.env("USER") ?? ""
        size: 13
        weight: Font.Medium
        color: Theme.alpha(Theme.tone(Theme.h, Theme.s * 0.4, 0.9), 0.5)
        opacity: root.at(0.5, 0.5)
    }

    // ---- typing (anywhere)
    focus: true
    Keys.onPressed: e => {
        const k = e.key;
        if (k === Qt.Key_Escape) {
            if (root.preview) Lock.preview = false;
            else { Lock.password = ""; Lock.message = ""; }
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            if (root.preview) { Lock.password = ""; Lock.message = "Preview: nothing is checked"; Lock.wrong(); }
            else Lock.submit();
        } else if (k === Qt.Key_Backspace) {
            Lock.password = e.modifiers & Qt.ControlModifier ? "" : Lock.password.slice(0, -1);
        } else if (e.text.length > 0 && e.text.charCodeAt(0) >= 32 && !Lock.checking) {
            Lock.password += e.text;
            Lock.message = "";
        }
        e.accepted = true;
    }
}
