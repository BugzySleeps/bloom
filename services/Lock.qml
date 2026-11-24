pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Locking: Wayland's session lock (lock/LockScreen.qml) and your password checked by PAM (the same "login"
// rules hyprlock uses). `rice lock` asks for it over IPC and falls back to hyprlock if this doesn't lock
// within 8 s. The flag file it writes means "should be locked": a shell that starts (or restarts after a
// crash) while it's there locks straight away, so the session is never left open.
Singleton {
    id: root

    property bool locked: false
    property bool preview: false        // the lock screen drawn in an ordinary window, to look at it (Esc closes)
    property bool boot: false           // locked at login: the screen plays its intro
    property string password: ""
    property string message: ""
    property int fails: 0
    readonly property bool checking: pam.active
    signal wrong()

    readonly property string flag: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/rice/locked"

    function lock(atBoot) {
        boot = !!atBoot;
        password = "";
        message = "";
        locked = true;
    }
    function unlock() {
        locked = false;
        password = "";
        message = "";
        fails = 0;
        Quickshell.execDetached(["rm", "-f", flag]);
    }
    function submit() {
        if (!locked || pam.active || password === "") return;
        message = "";
        pam.start();
    }

    PamContext {
        id: pam
        config: "login"
        onResponseRequiredChanged: {
            if (!responseRequired) return;
            respond(root.password);
        }
        onPamMessage: {
            if (messageIsError) root.message = message;
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlock();
                return;
            }
            root.fails++;
            root.password = "";
            root.message = result === PamResult.MaxTries ? "Too many tries, wait a moment" : "That's not it";
            root.wrong();
        }
    }

    // locked when the shell started? (rice lock wrote the flag; "boot" in it means at login)
    Process {
        running: true
        command: ["sh", "-c", "[ -f \"$1\" ] && { echo yes; cat \"$1\"; }", "sh", root.flag]
        stdout: StdioCollector {
            onStreamFinished: if (text.startsWith("yes")) root.lock(text.indexOf("boot") >= 0)
        }
    }
}
