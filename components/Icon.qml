import QtQuick
import qs.services

// A Material Symbols icon by name
Text {
    property string name
    property real size: 20
    property bool fill: false
    text: name
    color: Theme.text
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill ? 1 : 0, "wght": 450, "opsz": Math.min(48, Math.max(20, size)) })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
