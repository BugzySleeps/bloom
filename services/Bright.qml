pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The screen's backlight (read from sysfs, set with brightnessctl)
Singleton {
    id: root

    property string dev: "intel_backlight"
    property int max: 1
    property int raw: 0
    readonly property real level: max > 0 ? raw / max : 0
    readonly property bool present: max > 1

    signal changed()
    property bool ready: false
    Timer { running: true; interval: 1500; onTriggered: root.ready = true }

    Process {
        running: true
        command: ["sh", "-c", "d=$(ls /sys/class/backlight | head -1); echo $d; cat /sys/class/backlight/$d/max_brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                if (l.length === 2) { root.dev = l[0]; root.max = parseInt(l[1]) || 1; }
            }
        }
    }

    FileView {
        id: f
        path: "/sys/class/backlight/" + root.dev + "/actual_brightness"
        onLoaded: {
            const v = parseInt(text()) || 0;
            if (v !== root.raw) {
                root.raw = v;
                if (root.ready) root.changed();
            }
        }
    }
    // sysfs doesn't tell anyone when it changes, so look now and then (more often while the panel is open)
    Timer {
        interval: Ui.open ? 300 : 700
        repeat: true
        running: root.present
        onTriggered: f.reload()
    }

    function set(v) {
        v = Math.max(0.02, Math.min(1, v));
        root.raw = Math.round(v * max);
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(v * 100) + "%"]);
    }
}
