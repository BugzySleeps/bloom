pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// The music: whichever player is playing (else the last one that was)
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer last: null
    readonly property MprisPlayer playingNow: players.find(p => p.isPlaying) ?? null
    onPlayingNowChanged: if (playingNow) last = playingNow
    // a player to put first whenever it's there (part of its name, e.g. "cmus"): ipc media prefer <name>, "" for none
    property string prefer: ""
    readonly property MprisPlayer preferred: prefer === "" ? null
        : players.find(p => (p.identity + " " + (p.dbusName ?? "")).toLowerCase().includes(prefer.toLowerCase())) ?? null
    readonly property MprisPlayer player: preferred ?? playingNow ?? (players.includes(last) ? last : null) ?? players[0] ?? null

    readonly property bool active: !!player && title !== ""
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property real length: player?.lengthSupported ? player.length : 0
    property real position: 0
    readonly property real progress: length > 0 ? Math.min(1, position / length) : 0

    function toggle() { player?.togglePlaying(); }
    function next() { player?.next(); }
    function previous() { player?.previous(); }
    function seek(frac) {
        if (player?.canSeek && length > 0) {
            player.position = frac * length;
            position = frac * length;
        }
    }

    function time(sec) {
        sec = Math.max(0, Math.floor(sec));
        return Math.floor(sec / 60) + ":" + String(sec % 60).padStart(2, "0");
    }

    // MPRIS doesn't announce the position as it moves: read it while something plays
    Timer {
        interval: 500
        repeat: true
        running: root.playing
        triggeredOnStart: true
        onTriggered: root.position = root.player?.position ?? 0
    }
    Connections {
        target: root.player
        function onPostTrackChanged() { root.position = 0; }
        function onPositionChanged() { root.position = root.player.position; }
    }

    IpcHandler {
        target: "media"
        function prefer(name: string): void { root.prefer = name; }
    }
}
