pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The music's spectrum for the visualizer along the bottom (cava, on whichever output is playing)
Singleton {
    id: root

    readonly property int bars: 24      // shown mirrored (48 on screen): wider bands, more to react to
    property var values: []
    readonly property bool running: Settings.visualizer && Media.playing

    readonly property string conf: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/bloom-cava.conf"
    readonly property string text: [
        "[general]", "bars = " + bars, "framerate = 30", "autosens = 0", "sensitivity = 60000",   // fixed (measured at 54% volume): loud songs reach high, calm ones stay low
        "[input]", "method = pipewire",
        "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii",
        "ascii_max_range = 100", "bar_delimiter = 59", "frame_delimiter = 10",
        "[smoothing]", "noise_reduction = 66"
    ].join("\n")

    Process {
        running: root.running
        // cava-run keeps restarting cava, so it must be stopped by hand: a watcher outside this shell process
        // stops it once either this sh or the shell itself is gone (even if they were killed outright)
        // (and a shell reload doesn't stop the old one either, so each new one stops the last, by its pid file)
        command: ["sh", "-c", "pf=\"$2.pid\"; [ -f \"$pf\" ] && kill $(cat \"$pf\") 2>/dev/null; "
            + "printf '%s\\n' \"$1\" > \"$2\"; r=\"$HOME/.config/rice/cava-run\"; "
            // cava-run (BugzySleeps' dotfiles) follows whichever output is playing; elsewhere it's plain cava
            + "if [ -x \"$r\" ]; then \"$r\" \"$2\" & else cava -p \"$2\" & fi; c=$!; echo $c > \"$pf\"; me=$$; qs=$PPID; "
            + "alive() { s=$(cut -d' ' -f3 /proc/$1/stat 2>/dev/null); [ -n \"$s\" ] && [ \"$s\" != Z ]; }; "
            + "( while alive $me && alive $qs; do sleep 1; done; kill $c 2>/dev/null ) >/dev/null 2>&1 & "
            + "trap 'kill $c 2>/dev/null; exit' TERM INT HUP; wait $c", "sh", root.text, root.conf]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";");
                const out = [];
                for (let i = 0; i < root.bars; i++) out.push((parseInt(v[i]) || 0) / 100);
                root.values = out;
            }
        }
        onRunningChanged: if (!running) root.values = []
    }
}
