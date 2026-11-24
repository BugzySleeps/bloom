import QtQuick
import qs.services

Rectangle {
    radius: 24
    color: Theme.surfaceMid
    Behavior on color { ColorAnimation { duration: Theme.normal } }
}
