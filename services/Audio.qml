pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string icon: muted || volume < 0.01 ? "volume_off" : volume < 0.4 ? "volume_down" : "volume_up"

    signal changed()   // for the island to show the level
    onVolumeChanged: if (ready) changed()
    onMutedChanged: if (ready) changed()
    property bool ready: false
    Timer { running: true; interval: 1500; onTriggered: root.ready = true }

    function set(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted;
    }
}
