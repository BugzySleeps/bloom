pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// Wi-Fi (NetworkManager) and Bluetooth, just enough for two toggles
Singleton {
    id: root

    property bool wifi: false
    property string ssid: ""
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool bt: adapter?.enabled ?? false
    readonly property int btConnected: adapter ? adapter.devices.values.filter(d => d.connected).length : 0

    function toggleWifi() {
        wifi = !wifi;
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifi ? "on" : "off"]);
        later.restart();
    }
    function toggleBt() {
        if (adapter) adapter.enabled = !adapter.enabled;
    }

    Timer { id: later; interval: 2500; onTriggered: poll.running = true }
    Timer {
        interval: Ui.open ? 4000 : 20000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }
    Process {
        id: poll
        command: ["sh", "-c", "nmcli -t -f WIFI g; nmcli -t -f active,ssid dev wifi 2>/dev/null | sed -n 's/^yes://p' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.wifi = l[0].trim() === "enabled";
                root.ssid = (l[1] || "").trim();
            }
        }
    }
}
