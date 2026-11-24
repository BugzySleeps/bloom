pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// CPU, memory, temperature, disk and battery. Only measured while something shows them.
Singleton {
    id: root

    property int users: 0          // things on screen showing the stats (the panel, a widget)
    property real cpu: 0
    property real mem: 0
    property real memUsed: 0       // GiB
    property real memTotal: 0
    property real temp: 0          // °C
    property real disk: 0
    property string uptime: ""
    property var lastCpu: null

    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat?.isLaptopBattery ?? false
    readonly property real battery: bat?.percentage ?? 0
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging || bat?.state === UPowerDeviceState.FullyCharged

    Timer {
        interval: 2000
        repeat: true
        running: root.users > 0 || Ui.open
        triggeredOnStart: true
        onTriggered: {
            stat.reload(); meminfo.reload(); thermal.reload(); up.reload();
            if (!df.running) df.running = true;
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const p = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = p[3] + p[4], total = p.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total, di = idle - root.lastCpu.idle;
                root.cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
            }
            root.lastCpu = { total: total, idle: idle };
        }
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const get = k => parseInt((t.match(new RegExp(k + ":\\s+(\\d+)")) || [0, 0])[1]);
            const total = get("MemTotal"), avail = get("MemAvailable");
            root.memTotal = total / 1048576;
            root.memUsed = (total - avail) / 1048576;
            root.mem = total > 0 ? 1 - avail / total : 0;
        }
    }
    property string thermalPath: "/sys/class/thermal/thermal_zone0/temp"
    Process {
        running: true
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && echo $z/temp && exit; done; echo /sys/class/thermal/thermal_zone0/temp"]
        stdout: StdioCollector { onStreamFinished: root.thermalPath = text.trim() }
    }
    FileView {
        id: thermal
        path: root.thermalPath
        onLoaded: root.temp = (parseInt(text()) || 0) / 1000
    }
    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(parseFloat(text()));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            root.uptime = (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m";
        }
    }
    Process {
        id: df
        command: ["df", "--output=pcent", "/"]
        stdout: StdioCollector { onStreamFinished: root.disk = (parseInt(text.split("\n")[1]) || 0) / 100 }
    }
}
