import QtQuick
import qs.services

Text {
    property real size: 14
    property int weight: Font.Normal
    property real wdth: 100       // Google Sans Flex's width axis
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: size
    font.weight: weight
    font.variableAxes: ({ "wdth": wdth, "ROND": 100 })
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
