pragma Singleton

import QtQuick
import Quickshell

// The desktop widgets: their sizes, and where a new one goes
Singleton {
    readonly property var sizes: ({
        clock: [170, 170],
        date: [124, 148],
        weather: [158, 158],
        battery: [128, 128],
        music: [196, 196],
        stats: [138, 138]
    })
    // the shape each kind starts as (right-click a widget for another)
    readonly property var shapeOf: ({
        clock: "cookie12", date: "arch", weather: "circle", battery: "sunny", music: "cookie12", stats: "flower"
    })
    readonly property var shapes: ["circle", "cookie12", "cookie9", "cookie6", "cookie4", "clover4", "clover8", "sunny",
        "verySunny", "softBurst", "burst", "flower", "puffy", "pentagon", "gem", "triangle", "diamond", "arch", "square", "slanted"]

    readonly property var spots: ({
        clock: [0.08, 0.16],
        date: [0.92, 0.74],
        weather: [0.08, 0.7],
        battery: [0.9, 0.17],
        music: [0.24, 0.42],
        stats: [0.78, 0.44]
    })

    function place(kind) {
        const s = spots[kind] ?? [0.5, 0.5];
        return { kind: kind, x: s[0], y: s[1] };
    }

    function move(i, x, y) {
        const l = Settings.widgets.slice();
        l[i] = Object.assign({}, l[i], { x: Math.max(0, Math.min(1, x)), y: Math.max(0, Math.min(1, y)) });
        Settings.setWidgets(l);
    }

    function setShape(i, shape) {
        const l = Settings.widgets.slice();
        if (!l[i]) return;
        l[i] = Object.assign({}, l[i], { shape: shape });
        Settings.setWidgets(l);
    }
}
