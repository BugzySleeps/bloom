pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One seed colour makes every colour in the shell (Material-style tones), light or dark.
// The seed is a preset, or taken from the wallpaper.
Singleton {
    id: root

    readonly property var presets: [
        { name: "wallpaper", label: "Wallpaper", seed: "" },
        { name: "sand", label: "Sand", seed: "#b59a4c" },
        { name: "sage", label: "Sage", seed: "#6e8f5c" },
        { name: "moss", label: "Moss", seed: "#4f7a3a" },
        { name: "sky", label: "Sky", seed: "#4c8fbf" },
        { name: "lilac", label: "Lilac", seed: "#9a7fd6" },
        { name: "rose", label: "Rose", seed: "#c66b86" },
        { name: "ember", label: "Ember", seed: "#d4733f" },
        { name: "mono", label: "Mono", seed: "#8a8a8a" }
    ]

    property color wallSeed: "#b59a4c"
    readonly property color seed: {
        const p = presets.find(p => p.name === Settings.theme);
        return p && p.seed ? p.seed : wallSeed;
    }
    readonly property bool dark: Settings.dark

    readonly property real h: seed.hslHue < 0 ? 0 : seed.hslHue
    readonly property real s: Settings.theme === "mono" ? 0 : Math.max(0.18, seed.hslSaturation)

    function tone(hue, sat, l, a) {
        return Qt.hsla(((hue % 1) + 1) % 1, Math.max(0, Math.min(1, sat)), l, a === undefined ? 1 : a);
    }

    // surfaces: barely tinted
    readonly property color surface: dark ? tone(h, s * 0.22, 0.075) : tone(h, s * 0.35, 0.965)
    readonly property color surfaceLow: dark ? tone(h, s * 0.22, 0.105) : tone(h, s * 0.32, 0.94)
    readonly property color surfaceMid: dark ? tone(h, s * 0.22, 0.13) : tone(h, s * 0.3, 0.915)
    readonly property color surfaceHigh: dark ? tone(h, s * 0.22, 0.17) : tone(h, s * 0.28, 0.885)
    readonly property color surfaceTop: dark ? tone(h, s * 0.22, 0.215) : tone(h, s * 0.26, 0.85)
    readonly property color text: dark ? tone(h, s * 0.2, 0.91) : tone(h, s * 0.3, 0.12)
    readonly property color textDim: dark ? tone(h, s * 0.15, 0.7) : tone(h, s * 0.18, 0.36)
    readonly property color outline: dark ? tone(h, s * 0.12, 0.42) : tone(h, s * 0.12, 0.6)
    readonly property color outlineSoft: dark ? tone(h, s * 0.15, 0.26) : tone(h, s * 0.18, 0.8)

    // the accent and its family
    readonly property color primary: dark ? tone(h, Math.min(0.75, s + 0.1), 0.76) : tone(h, Math.min(0.6, s + 0.05), 0.42)
    readonly property color onPrimary: dark ? tone(h, s * 0.8, 0.16) : tone(h, s * 0.2, 0.98)
    readonly property color primaryBox: dark ? tone(h, s * 0.55, 0.28) : tone(h, s * 0.8, 0.86)
    readonly property color onPrimaryBox: dark ? tone(h, s * 0.6, 0.9) : tone(h, s * 0.8, 0.16)
    readonly property color secondary: dark ? tone(h, s * 0.35, 0.74) : tone(h, s * 0.35, 0.4)
    readonly property color secondaryBox: dark ? tone(h, s * 0.3, 0.25) : tone(h, s * 0.4, 0.87)
    readonly property color onSecondaryBox: dark ? tone(h, s * 0.35, 0.88) : tone(h, s * 0.4, 0.17)
    readonly property color tertiary: dark ? tone(h + 0.17, Math.min(0.6, s), 0.76) : tone(h + 0.17, Math.min(0.6, s), 0.4)
    readonly property color tertiaryBox: dark ? tone(h + 0.17, s * 0.45, 0.27) : tone(h + 0.17, s * 0.6, 0.86)
    readonly property color onTertiaryBox: dark ? tone(h + 0.17, s * 0.5, 0.9) : tone(h + 0.17, s * 0.6, 0.17)
    readonly property color error: dark ? "#f2b8b5" : "#b3261e"

    readonly property string font: "Google Sans Flex"
    readonly property string icons: "Material Symbols Rounded"

    // springy, but not silly
    readonly property int quick: 180
    readonly property int normal: 320
    readonly property int slow: 520

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // the wallpaper's seed: its most colourful common colour (tools/seed.py)
    readonly property string wallPath: Settings.wallpaper || Qt.resolvedUrl("../assets/wallpaper.png").toString().replace("file://", "")
    onWallPathChanged: seeder.running = true
    Process {
        id: seeder
        running: true
        command: ["python3", "-I", Quickshell.shellDir + "/tools/seed.py", root.wallPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const c = text.trim();
                if (/^#[0-9a-fA-F]{6}$/.test(c))
                    root.wallSeed = c;
            }
        }
    }

    // Hyprland's focused-window border follows the accent
    readonly property string border: primary.toString()
    onBorderChanged: borderTimer.restart()
    Timer {
        id: borderTimer
        interval: 300
        onTriggered: {
            const hex = c => c.toString().replace("#", "").slice(-6);
            Quickshell.execDetached(["hyprctl", "eval",
                `hl.config({ general = { col = { active_border = { colors = { "rgba(${hex(root.primary)}cc)" }, angle = 0 }, inactive_border = "rgba(${hex(root.outlineSoft)}55)" } } })`]);
            // the mouse's LEDs (rice's leds service reads this): the same hue, but vivid, since pale tones look
            // washed out on an LED
            const led = Settings.theme === "mono" ? root.tone(0, 0, 0.75) : root.tone(root.h, Math.max(0.75, root.s), 0.5);
            Quickshell.execDetached(["sh", "-c", 'mkdir -p "$HOME/.local/state/bloom" && printf "%s\\n" "$1" > "$HOME/.local/state/bloom/mouse"',
                "sh", "#" + hex(led)]);
        }
    }
}
