pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Your little characters for the island's panel: every picture in ~/.local/share/bloom/team (png, webp, avif,
// jpg or an animated gif), in file-name order; tools/team.py trims and shrinks them into ~/.cache/bloom/team. The name shown is the file name: "01-some_name.png" shows "Some Name".
// They're your own files and stay out of the shell's folder.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/bloom/team"
    property var members: []     // [{ path, name, gif }]

    function nice(file) {
        return file.replace(/\.[^.]+$/, "").replace(/^\d+[-_ ]*/, "").replace(/[-_]+/g, " ")
            .replace(/([a-z])([A-Z])/g, "$1 $2")          // MrGameAndWatch → Mr Game And Watch
            .replace(/\b\w/g, c => c.toUpperCase())
            .replace(/\bAnd\b/g, "&").replace(/^Mr /, "Mr. ");
    }

    readonly property string cache: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/bloom/team"
    Process {
        id: scan
        running: true
        command: ["sh", "-c", "mkdir -p \"$1\"; exec python3 -I \"$3\" \"$1\" \"$2\"", "sh", root.dir, root.cache, Quickshell.shellDir + "/tools/team.py"]
        stdout: StdioCollector {
            onStreamFinished: root.members = text.split("\n").filter(l => l.includes("\t")).slice(0, 8).map(l => {
                const [path, file] = l.split("\t");
                return { path: path, name: root.nice(file), gif: /\.gif$/i.test(path) };
            })
        }
    }
    // look again whenever the panel opens (so new files just turn up)
    Connections {
        target: Ui
        function onOpenChanged() { if (Ui.open) scan.running = true; }
    }
}
