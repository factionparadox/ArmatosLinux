import QtQuick

// Where goods come from. Foreign (Flatpak) goods get a porphyry seal that
// says PEREGRINA; the empire's own carry their source in small letters.
Item {
    id: root
    property var resource
    readonly property bool foreign: Theme.isForeign(resource)
    readonly property string line: Theme.originLine(resource)

    visible: line !== ""
    implicitWidth: label.implicitWidth + (foreign ? 20 : 0)
    implicitHeight: 22

    Porphyry {
        anchors.fill: parent
        visible: root.foreign
        Bevel { depth: 0.45 }
    }

    Carved {
        id: label
        anchors.centerIn: parent
        text: root.foreign && root.resource && root.resource.displayOrigin
              ? "PEREGRINA · " + root.resource.displayOrigin.toUpperCase() : root.line
        size: 10
        spacing: 0.2
        tone: root.foreign ? "gilt" : "faint"
    }
}
