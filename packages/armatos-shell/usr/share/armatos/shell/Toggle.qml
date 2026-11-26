import QtQuick
import QtQuick.Layouts

// An order that is given or withdrawn: a small niche, filled with
// porphyry when on, a carved name and a line of explanation.
Item {
    id: root
    property string label
    property string detail
    property bool on: false
    signal toggled()

    implicitHeight: 32
    Layout.fillWidth: true

    Niche {
        id: box
        width: 22; height: 22
        anchors.verticalCenter: parent.verticalCenter

        Porphyry {
            anchors { fill: parent; margins: 4 }
            visible: root.on
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Qt.rgba(1, 1, 1, 0.25) }
        }
    }
    Carved {
        id: name
        anchors { left: box.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
        width: 112
        text: root.label
        size: 14
        spacing: 0.08
        tone: area.containsMouse ? "red" : "ink"
    }
    Carved {
        anchors { left: name.right; leftMargin: 12; right: parent.right; verticalCenter: parent.verticalCenter }
        text: root.detail
        family: Theme.serif
        size: 16
        weight: Font.Medium
        italic: true
        elide: Text.ElideRight
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
