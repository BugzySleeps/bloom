pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What the island is doing, and the shortcuts (qs -c bloom ipc call ...)
Singleton {
    id: root

    property bool open: false        // the panel is pulled down
    property string page: "home"     // home | style
    property bool launcher: false    // the app picker (launcher/Launcher.qml)
    onLauncherChanged: if (launcher) open = false
    property string peeking: ""      // "" | volume | brightness | notif: a quick look without opening
    property int shapeFor: -1
    // for screenshots: hides your Wi-Fi name, user name and notifications (ipc island privacy), and shows another
    // folder in the wallpaper strip (ipc island wallFolder <path>, "" for ~/Pictures/wallpapers)
    property bool privacy: false
    property string wallFolder: ""

    function toggle(p) {
        if (open && (!p || p === page)) { open = false; return; }
        page = p || "home";
        peeking = "";
        open = true;
    }
    function close() { open = false; }

    function peek(what, ms) {
        if (open) return;
        peeking = what;
        peekTimer.interval = ms || 1600;
        peekTimer.restart();
    }
    Timer {
        id: peekTimer
        onTriggered: root.peeking = ""
    }

    Connections {
        target: Audio
        function onChanged() { root.peek("volume"); }
    }
    Connections {
        target: Bright
        function onChanged() { root.peek("brightness"); }
    }

    IpcHandler {
        target: "island"
        function toggle(): void { root.toggle(); }
        function open(page: string): void { root.page = page || "home"; root.open = true; }
        function close(): void { root.close(); }
        function privacy(): void { root.privacy = !root.privacy; }
        function wallFolder(path: string): void { root.wallFolder = path; }
        function state(): string { return JSON.stringify({ open: root.open, page: root.page, peeking: root.peeking, privacy: root.privacy }); }
    }
    // the shortcuts the rest of the desktop already uses (SUPER+N, SUPER+A, SUPER+T, SUPER+I, SUPER+W)
    IpcHandler {
        target: "panel"
        function toggle(which: string): void { root.toggle("home"); }
    }
    // SUPER+R (only toggle: `launcher open :` for emoji is left to fail, so the emoji picker still runs)
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.launcher = !root.launcher; }
        // `launcher open :` is the emoji shortcut (SUPER+.): there's no emoji page, so the emoji picker runs
        function open(q: string): void {
            if (q.startsWith(":")) Quickshell.execDetached(["sh", "-c", "~/.local/bin/hypr-emoji"]);
            else root.launcher = true;
        }
    }
    IpcHandler {
        target: "wall"
        function toggle(): void { root.toggle("style"); }
    }
    IpcHandler {
        target: "settings"
        function toggle(): void { root.toggle("style"); }
    }
    IpcHandler {
        target: "widgets"
        function edit(): void { root.toggle("style"); }
    }
    // `rice lock` asks here first (lock, or boot at login) and waits for isLocked; see services/Lock.qml
    IpcHandler {
        target: "lock"
        function lock(): void { Lock.lock(false); }
        function boot(): void { Lock.lock(true); }
        function isLocked(): bool { return Lock.locked; }
        function preview(): void { Lock.preview = !Lock.preview; }
    }
}
