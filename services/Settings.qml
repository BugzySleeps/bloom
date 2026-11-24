pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Everything you can change, saved in ~/.local/state/bloom/settings.json (on purpose, not much)
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/bloom"

    property alias theme: a.theme            // a colour name from Theme.presets, or "wallpaper"
    property alias dark: a.dark
    property alias wallpaper: a.wallpaper    // a path; "" is Bloom's own
    property alias lyrics: a.lyrics          // the song's words on the wallpaper
    property alias visualizer: a.visualizer  // the bars along the bottom
    property alias widgets: a.widgets        // [{ kind, x, y }] on the desktop
    property alias dnd: a.dnd
    property alias lat: a.lat                // for the weather; found once from your connection
    property alias lon: a.lon
    property alias place: a.place
    property alias fahrenheit: a.fahrenheit
    property alias appUse: a.appUse          // how often each app was opened from the picker (it sorts by this)

    function setWidgets(list) {
        a.widgets = list.slice();
    }

    FileView {
        id: file
        path: root.dir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: a
            property string theme: "wallpaper"
            property bool dark: true
            property string wallpaper: ""
            property bool lyrics: true
            property bool visualizer: true
            property bool dnd: false
            property var widgets: [
                { kind: "clock", x: 0.08, y: 0.22 },
                { kind: "date", x: 0.9, y: 0.72 },
                { kind: "weather", x: 0.07, y: 0.62 },
                { kind: "battery", x: 0.9, y: 0.22 }
            ]
            property real lat: 0
            property real lon: 0
            property string place: ""
            property bool fahrenheit: false
            property var appUse: ({})
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.dir]
    }
}
