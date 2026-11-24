import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The real lock (Wayland's session lock: nothing gets past it until PAM says yes) and a preview of the same
// screen in an ordinary window, so it can be looked at without locking anything (`qs -c bloom ipc call lock preview`).
Scope {
    WlSessionLock {
        id: session
        locked: Lock.locked
        WlSessionLockSurface {
            color: "black"
            LockScene {
                anchors.fill: parent
                Component.onCompleted: forceActiveFocus()
            }
        }
    }

    PanelWindow {
        visible: Lock.preview && !Lock.locked
        screen: Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "bloom-lock-preview"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "black"
        Loader {
            anchors.fill: parent
            active: parent.visible
            sourceComponent: LockScene {
                preview: true
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
