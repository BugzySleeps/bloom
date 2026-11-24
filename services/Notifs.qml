pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notifications drop out of the island one at a time; the last few wait in the panel
Singleton {
    id: root

    property var list: []          // newest first
    property var shown: null       // the one the island is showing right now
    readonly property int count: list.length

    NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        actionsSupported: true
        onNotification: n => {
            n.tracked = true;
            root.list = [n].concat(root.list).slice(0, 30);
            n.closed.connect(() => root.forget(n));
            if (!Ui.privacy && (!Settings.dnd || n.urgency === NotificationUrgency.Critical)) {
                root.shown = n;
                Ui.peek("notif", n.urgency === NotificationUrgency.Critical ? 9000 : 5000);
            }
        }
    }

    function forget(n) {
        list = list.filter(x => x !== n);
        if (shown === n) shown = null;
    }
    function dismiss(n) {
        n?.dismiss();
        forget(n);
    }
    function clear() {
        list.slice().forEach(n => n.dismiss());
        list = [];
        shown = null;
    }
}
