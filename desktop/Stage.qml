import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Over the wallpaper, under your windows: the song's words, lighting up as they're sung, and the
// visualizer along the bottom. Each can be switched off; neither takes clicks.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 380
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "bloom-stage"
    color: "transparent"
    mask: Region {}

    readonly property bool showLyrics: Settings.lyrics && Lyrics.state === "synced" && Media.active
    readonly property bool showBars: Settings.visualizer && Media.playing
    visible: showLyrics || showBars || bars.opacity > 0

    readonly property color ink: Theme.tone(Theme.h, Math.min(0.5, Theme.s), 0.95)
    readonly property color glow: Theme.tone(Theme.h, Theme.s * 0.6, 0.08)

    // ---- the words
    Item {
        id: words
        anchors.horizontalCenter: parent.horizontalCenter
        y: 70
        width: Math.min(parent.width - 160, 1100)
        height: 180
        opacity: win.showLyrics && Lyrics.current !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.slow } }

        layer.enabled: opacity > 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.alpha(win.glow, 0.85)
            shadowBlur: 0.9
            shadowVerticalOffset: 2
            shadowHorizontalOffset: 0
        }

        // a gentle rise each time the line changes
        property real lift: 0
        Connections {
            target: Lyrics
            function onIndexChanged() { rise.restart(); }
        }
        NumberAnimation { id: rise; target: words; property: "lift"; from: 18; to: 0; duration: 420; easing.type: Easing.OutCubic }

        Txt {
            id: prev
            anchors.horizontalCenter: parent.horizontalCenter
            y: 4 + words.lift
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Lyrics.previous
            size: 17
            weight: Font.Medium
            color: Theme.alpha(win.ink, 0.45)
        }

        Flow {
            id: line
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40 + words.lift
            width: Math.min(parent.width, implicitW)
            spacing: 11
            readonly property var parts: Lyrics.current.split(/\s+/).filter(w => w !== "")
            // a rough guess at which word is being sung: longer words take longer
            readonly property int sung: {
                const p = parts, t = Lyrics.lineProgress;
                if (p.length === 0) return 0;
                const w = p.map(x => x.length + 2), total = w.reduce((a, b) => a + b, 0);
                let acc = 0;
                for (let i = 0; i < p.length; i++) {
                    acc += w[i];
                    if (acc / total > t) return i;
                }
                return p.length;
            }
            property real implicitW: 0
            onPartsChanged: Qt.callLater(() => {
                let w = 0;
                for (let i = 0; i < rep.count; i++) w += rep.itemAt(i).implicitWidth + spacing;
                implicitW = Math.max(40, w - spacing + 2);
            })
            Repeater {
                id: rep
                model: line.parts
                Txt {
                    required property string modelData
                    required property int index
                    text: modelData
                    size: 38
                    weight: Font.Bold
                    wdth: 96
                    elide: Text.ElideNone
                    color: index <= line.sung ? win.ink : Theme.alpha(win.ink, 0.38)
                    Behavior on color { ColorAnimation { duration: 220 } }
                    scale: index === line.sung ? 1.04 : 1
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                }
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: line.bottom
            anchors.topMargin: 10 + words.lift * 0.5
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Lyrics.next
            size: 17
            weight: Font.Medium
            color: Theme.alpha(win.ink, 0.45)
        }
    }

    // ---- the visualizer
    Item {
        id: bars
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 150
        opacity: win.showBars ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.slow } }

        readonly property int n: Cava.bars * 2
        readonly property real slot: width / n
        Repeater {
            model: bars.n
            Rectangle {
                required property int index
                // the bass in the middle, mirrored out to both edges
                readonly property int band: Math.abs(index - (bars.n - 1) / 2) | 0
                // a gentle curve lifts the quiet parts so every bar moves, not just the bass
                // cava's sensitivity is fixed, so the height follows how loud the song really is
                readonly property real v: Cava.values.length ? Math.pow(Math.min(1, Cava.values[Math.min(Cava.bars - 1, band)]), 1.2) : 0
                x: index * bars.slot + bars.slot * 0.18
                width: bars.slot * 0.64
                height: Math.max(width, 6 + v * (bars.height - 6))
                y: bars.height - height
                radius: width / 2
                color: Theme.alpha(Theme.primary, 0.3 + v * 0.55)
            }
        }
    }
}
