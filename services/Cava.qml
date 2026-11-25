pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The music's spectrum for the visualizer along the bottom (cava, on whichever output is playing)
Singleton {
    id: root

    property real peak: floor
    readonly property real floor: 300   // in cava's 0..1000 at sensitivity 250: about a normal song's level
    readonly property int bars: 24      // shown mirrored (48 on screen): wider bands, more to react to
    property var values: []
    readonly property bool running: Settings.visualizer && Media.playing

    readonly property string conf: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/bloom-cava.conf"
    readonly property string text: [
        // Fixed, low sensitivity with lots of headroom (0..1000) so cava never clips on any output or
        // volume; the level below (peak) then scales it. 60000 fit the quiet USB dongle and pinned every
        // bar on the laptop speaker (~100x louder), so a single fixed number can't work everywhere.
        "[general]", "bars = " + bars, "framerate = 30", "autosens = 0", "sensitivity = 250",
        "[input]", "method = pipewire",
        "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii",
        "ascii_max_range = 1000", "bar_delimiter = 59", "frame_delimiter = 10",
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
                const raw = [];
                let top = 0;
                for (let i = 0; i < root.bars; i++) {
                    const x = parseInt(v[i]) || 0;
                    raw.push(x);
                    if (x > top) top = x;
                }
                // Loudness level: jumps up at once with anything louder, sinks back slowly (half
                // every ~minute), so a calm song after a loud one stays calm but nothing stays pinned.
                // The floor keeps silence and very quiet songs from being blown up to full height.
                root.peak = Math.max(top, root.peak * 0.99962, root.floor);
                const out = [];
                for (let i = 0; i < root.bars; i++) out.push(Math.min(1, raw[i] / root.peak * 0.95));
                root.values = out;
            }
        }
        onRunningChanged: if (!running) root.values = []
    }
}
