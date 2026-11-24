//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

// Bloom: a small Quickshell shell made of Material 3 Expressive shapes.
// A floating bar (workspaces, a dynamic island, the time), shaped desktop widgets, the song's lyrics and a
// visualizer on the wallpaper. One colour makes the whole theme.
import QtQuick
import Quickshell
import qs.services
import qs.bar
import qs.island
import qs.desktop
import qs.launcher
import qs.lock

ShellRoot {
    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }
    Variants {
        model: Quickshell.screens
        Stage {}
    }
    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Variants {
        model: Quickshell.screens
        IslandWindow {}
    }
    Variants {
        model: Quickshell.screens
        Launcher {}
    }
    LockScreen {}

    // services that should start straight away
    Component.onCompleted: {
        Notifs.count;
        Weather.ready;
        Lyrics.state;
        Theme.seed;
    }
}
