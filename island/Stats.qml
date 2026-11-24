import QtQuick
import qs.services
import qs.components

// The computer at a glance: four shapes, each with a wavy ring showing how full it is
Card {
    id: root

    readonly property var items: [
        { label: "CPU", shape: "cookie9", value: () => Sys.cpu, text: () => Math.round(Sys.cpu * 100) + "%" },
        { label: "Memory", shape: "clover4", value: () => Sys.mem, text: () => Sys.memUsed.toFixed(1) + "G" },
        { label: "Temp", shape: "sunny", value: () => Math.min(1, Sys.temp / 100), text: () => Math.round(Sys.temp) + "°" },
        Sys.hasBattery
            ? { label: Sys.charging ? "Charging" : "Battery", shape: "pentagon", value: () => Sys.battery, text: () => Math.round(Sys.battery * 100) + "%" }
            : { label: "Disk", shape: "pentagon", value: () => Sys.disk, text: () => Math.round(Sys.disk * 100) + "%" }
    ]

    Row {
        anchors.centerIn: parent
        spacing: 22
        Repeater {
            model: root.items
            Column {
                required property var modelData
                required property int index
                spacing: 4
                Item {
                    width: 82; height: 82
                    WavyRing {
                        anchors.fill: parent
                        value: parent.parent.modelData.value()
                        color: [Theme.primary, Theme.tertiary, Theme.secondary, Theme.primary][parent.parent.index]
                        thick: 4.5
                        amp: 1.6
                        waves: 11
                    }
                    MShape {
                        anchors.centerIn: parent
                        width: 54; height: 54
                        shape: parent.parent.modelData.shape
                        color: [Theme.primaryBox, Theme.tertiaryBox, Theme.secondaryBox, Theme.primaryBox][parent.parent.index]
                        Txt {
                            anchors.centerIn: parent
                            text: parent.parent.parent.modelData.text()
                            size: 13
                            weight: Font.Bold
                            color: [Theme.onPrimaryBox, Theme.onTertiaryBox, Theme.onSecondaryBox, Theme.onPrimaryBox][parent.parent.parent.index]
                        }
                    }
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.modelData.label
                    size: 11.5
                    color: Theme.textDim
                }
            }
        }
    }
}
