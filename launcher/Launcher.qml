import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The app picker (SUPER+R): a big shape in the middle of the screen that you type into, and the apps that
// match in a ring around it. The ring spins to put the one you've picked at the top, and spins round again
// whenever what you type changes the list. Enter opens, Esc or a click outside closes. Arrows / Tab / the
// scroll wheel go round the ring; past the eighth app the ring turns over to the next eight.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData
    visible: Ui.launcher && modelData === Quickshell.screens[0]

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bloom-launcher"
    // a window that appears already asking for the keyboard gets it (you open it with a key and type)
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    readonly property int slots: 8
    readonly property real ringR: 168

    property string query: ""
    property int sel: 0
    readonly property int page: Math.floor(sel / slots)
    readonly property var shown: list.slice(page * slots, page * slots + slots)

    readonly property var all: DesktopEntries.applications.values
        .filter(a => !a.noDisplay && a.name)
        .sort((a, b) => (Settings.appUse[b.id] ?? 0) - (Settings.appUse[a.id] ?? 0) || a.name.localeCompare(b.name))
    function score(a, q) {
        const n = a.name.toLowerCase();
        if (n.startsWith(q)) return 4;
        if (n.split(/\s+/).some(w => w.startsWith(q))) return 3;
        if (n.includes(q)) return 2;
        return [a.genericName, a.comment, (a.keywords || []).join(" "), a.id].join(" ").toLowerCase().includes(q) ? 1 : 0;
    }
    readonly property var list: {
        const q = query.trim().toLowerCase();
        if (q === "") return all;
        return all.map(a => ({ a: a, s: score(a, q) })).filter(x => x.s > 0)
            .sort((x, y) => y.s - x.s || (Settings.appUse[y.a.id] ?? 0) - (Settings.appUse[x.a.id] ?? 0))
            .map(x => x.a);
    }

    // ---- the motion: `turn` is where the ring points (degrees); the selected slot always ends up on top
    property real turn: 0
    Behavior on turn { NumberAnimation { duration: 520; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
    property real intro: 0          // 0 → 1 when it opens: the middle grows, the apps fly out
    property real pop: 1            // 0 → 1 each time the list changes: the apps pop back in
    NumberAnimation { id: introAnim; target: win; property: "intro"; from: 0; to: 1; duration: 560; easing.type: Easing.OutCubic }
    NumberAnimation { id: popAnim; target: win; property: "pop"; from: 0; to: 1; duration: 460; easing.type: Easing.OutCubic }

    function aim() {   // turn so the selected slot sits at the top, going the short way round
        const want = -(sel % slots) * 360 / slots;
        let d = ((want - turn) % 360 + 540) % 360 - 180;
        turn += d;
    }
    onListChanged: {
        sel = 0;
        turn -= 360 / slots * 3;    // a spin for every change in the list
        aim();
        popAnim.restart();
    }
    onPageChanged: { turn -= 360; aim(); popAnim.restart(); }
    onSelChanged: aim()

    onVisibleChanged: if (visible) {
        query = "";
        sel = 0;
        turn = -90;
        aim();
        intro = 0;
        introAnim.restart();
        pop = 1;
        keys.forceActiveFocus();
    }

    function launch(a) {
        if (!a) return;
        const use = Object.assign({}, Settings.appUse);
        use[a.id] = (use[a.id] ?? 0) + 1;
        Settings.appUse = use;
        a.execute();
        Ui.launcher = false;
    }
    function move(d) {
        if (list.length === 0) return;
        sel = (sel + d + list.length) % list.length;
    }

    // ---- the dim behind it; a click anywhere off the shapes closes it
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.surface, 0.55 * win.intro)
    }
    MouseArea {
        anchors.fill: parent
        onClicked: Ui.launcher = false
        onWheel: w => win.move(w.angleDelta.y > 0 ? -1 : 1)
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            const k = e.key, ctrl = e.modifiers & Qt.ControlModifier;
            if (k === Qt.Key_Escape) Ui.launcher = false;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) win.launch(win.list[win.sel]);
            else if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_Tab) win.move(1);
            else if (k === Qt.Key_Left || k === Qt.Key_Up || k === Qt.Key_Backtab) win.move(-1);
            else if (k === Qt.Key_Backspace) win.query = ctrl ? win.query.replace(/\S*\s*$/, "") : win.query.slice(0, -1);
            else if (ctrl && k === Qt.Key_U) win.query = "";
            else if (!ctrl && e.text.length > 0 && e.text.charCodeAt(0) >= 32) win.query += e.text;
            e.accepted = true;
        }
    }

    Item {
        id: stage
        anchors.centerIn: parent
        width: 2 * win.ringR + 160
        height: width

        // ---- the middle: the theme's shape, turning a little with every letter
        MShape {
            id: core
            anchors.centerIn: parent
            width: 178; height: 178
            scale: 0.55 + 0.45 * win.intro
            opacity: win.intro
            shape: win.list.length === 0 ? "cookie4" : win.query === "" ? "cookie12" : "clover8"
            color: Theme.primary
            property real twist: 0
            spin: twist + (1 - win.intro) * -120
            Behavior on twist { NumberAnimation { duration: 480; easing.type: Easing.OutBack } }
            Connections {
                target: win
                function onQueryChanged() { core.twist += 360 / 16; }
            }
            MouseArea { anchors.fill: parent; onClicked: win.launch(win.list[win.sel]) }

            Column {
                anchors.centerIn: parent
                width: 124
                spacing: 2
                Item {
                    width: parent.width
                    height: 40
                    Txt {
                        id: typed
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideLeft
                        text: win.query === "" ? "Search" : win.query
                        size: win.query.length > 7 ? 17 : 23
                        weight: Font.Bold
                        color: win.query === "" ? Theme.alpha(Theme.onPrimary, 0.5) : Theme.onPrimary
                    }
                    Rectangle {   // the caret
                        visible: win.query !== ""
                        x: typed.x + typed.width + 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2; height: 22; radius: 1
                        color: Theme.onPrimary
                        SequentialAnimation on opacity {
                            running: win.visible
                            loops: Animation.Infinite
                            PauseAnimation { duration: 520 }
                            NumberAnimation { to: 0; duration: 120 }
                            PauseAnimation { duration: 380 }
                            NumberAnimation { to: 1; duration: 120 }
                        }
                    }
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: win.list.length === 0 ? "No apps" : (win.list[win.sel]?.name ?? "")
                    size: 11.5
                    weight: Font.DemiBold
                    color: Theme.alpha(Theme.onPrimary, 0.8)
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: win.list.length > win.slots
                    text: (win.page + 1) + " / " + Math.ceil(win.list.length / win.slots)
                    size: 11
                    color: Theme.alpha(Theme.onPrimary, 0.55)
                }
            }
        }

        // ---- the ring of apps
        Repeater {
            model: win.slots
            Item {
                id: slot
                required property int index
                readonly property var app: win.shown[index] ?? null
                readonly property bool on: !!app && win.page * win.slots + index === win.sel
                // where it sits: its place on the ring plus the ring's turn, flying out from the middle as it opens
                readonly property real a: (index * 360 / win.slots + win.turn - 90) * Math.PI / 180
                readonly property real enter: Math.max(0, Math.min(1, win.intro * 1.6 - index * 0.06)) * Math.max(0, Math.min(1, win.pop * 1.5 - index * 0.05))
                readonly property real r: win.ringR * (0.35 + 0.65 * enter)
                width: 64; height: 64
                x: stage.width / 2 + Math.cos(a) * r - width / 2
                y: stage.height / 2 + Math.sin(a) * r - height / 2
                visible: !!app
                opacity: enter
                scale: (0.4 + 0.6 * enter) * (on ? 1.25 : hov.hovered ? 1.08 : 1)
                Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutBack } }

                Icon {   // for apps whose icon can't be found
                    anchors.centerIn: parent
                    visible: appIcon.status !== Image.Ready
                    name: "apps"
                    size: 40
                    fill: true
                    color: slot.on ? Theme.primary : Theme.textDim
                }
                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 52; height: 52
                    sourceSize: Qt.size(104, 104)
                    source: slot.app ? Quickshell.iconPath(slot.app.icon, true) : ""
                    asynchronous: true
                    smooth: true
                }
                Txt {
                    anchors.top: parent.bottom
                    anchors.topMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 110
                    horizontalAlignment: Text.AlignHCenter
                    text: slot.app?.name ?? ""
                    size: 10.5
                    weight: slot.on ? Font.Bold : Font.Medium
                    color: slot.on ? Theme.primary : Theme.text
                    style: Text.Outline
                    styleColor: Theme.alpha(Theme.surface, 0.35)
                }
                HoverHandler {
                    id: hov
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler { onTapped: win.launch(slot.app) }
            }
        }
    }
}
