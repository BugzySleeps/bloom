pragma Singleton

import QtQuick
import Quickshell

// Timed lyrics for the song that's playing, from lrclib.net (only the artist, title and length are sent)
Singleton {
    id: root

    property var lines: []          // [{ t, text }]
    property string state: "none"   // none | loading | synced | plain | instrumental
    readonly property bool wanted: Settings.lyrics && Media.active
    readonly property string key: Media.artist + "\u0001" + Media.title
    property var cache: ({})
    property int ticket: 0

    // a smooth clock between MPRIS's half-second reads
    property real base: 0
    property real baseAt: 0
    property real now: 0
    readonly property int index: {
        let i = -1;
        for (let k = 0; k < lines.length; k++) {
            if (lines[k].t <= now + 0.15) i = k;
            else break;
        }
        return i;
    }
    readonly property string current: index >= 0 ? lines[index].text : ""
    readonly property string previous: index > 0 ? lines[index - 1].text : ""
    readonly property string next: index + 1 < lines.length ? lines[index + 1].text : ""
    // how far through the current line we are (0..1), for the words lighting up
    readonly property real lineProgress: {
        if (index < 0) return 0;
        const end = index + 1 < lines.length ? lines[index + 1].t : lines[index].t + 4;
        const span = Math.min(end - lines[index].t, Math.max(1.2, lines[index].text.length * 0.075));
        return Math.max(0, Math.min(1, (now - lines[index].t) / Math.max(0.3, span)));
    }

    Connections {
        target: Media
        function onPositionChanged() {
            root.base = Media.position;
            root.baseAt = Date.now();
        }
    }
    Timer {
        interval: 50
        repeat: true
        running: root.state === "synced" && Media.playing && root.wanted
        onTriggered: root.now = root.base + (Date.now() - root.baseAt) / 1000
    }

    onKeyChanged: wait.restart()
    onWantedChanged: wait.restart()
    Timer {
        id: wait
        interval: 400
        onTriggered: root.fetch()
    }

    function fetch() {
        lines = [];
        if (!wanted) { state = "none"; return; }
        const k = key;
        if (cache[k]) { use(cache[k]); return; }
        state = "loading";
        const mine = ++ticket;
        const q = "artist_name=" + encodeURIComponent(Media.artist) + "&track_name=" + encodeURIComponent(Media.title);
        get("https://lrclib.net/api/get?" + q + (Media.length > 0 ? "&duration=" + Math.round(Media.length) : ""), (ok, d) => {
            if (mine !== ticket) return;
            if (ok && d && (d.syncedLyrics || d.instrumental)) { keep(k, d); return; }
            get("https://lrclib.net/api/search?" + q, (ok2, list) => {
                if (mine !== ticket) return;
                const best = ok2 && Array.isArray(list) ? (list.find(r => r.syncedLyrics) ?? list.find(r => r.plainLyrics) ?? null) : null;
                keep(k, best ?? d);
            });
        });
    }

    function get(url, done) {
        const x = new XMLHttpRequest();
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE) return;
            let d = null;
            try { d = JSON.parse(x.responseText); } catch (e) {}
            done(x.status === 200, d);
        };
        x.open("GET", url);
        x.setRequestHeader("User-Agent", "Bloom shell");
        x.send();
    }

    function keep(k, d) {
        const e = !d ? { state: "none" }
            : d.instrumental ? { state: "instrumental" }
            : d.syncedLyrics ? { state: "synced", lines: parse(d.syncedLyrics) }
            : { state: "none" };
        cache[k] = e;
        use(e);
    }

    function use(e) {
        lines = e.lines ?? [];
        state = e.state;
        base = Media.position;
        baseAt = Date.now();
        now = base;
    }

    function parse(lrc) {
        const out = [];
        for (const raw of lrc.split("\n")) {
            const m = raw.match(/^\[(\d+):(\d+(?:\.\d+)?)\](.*)$/);
            if (m) out.push({ t: parseInt(m[1]) * 60 + parseFloat(m[2]), text: m[3].trim() });
        }
        out.sort((a, b) => a.t - b.t);
        return out;
    }
}
