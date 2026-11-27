import QtQuick

// A stone to press: a dressed slab with a carved word. Porphyry for the
// command that matters, marble for the rest.
Item {
    id: root

    property string text
    property bool porphyry: false
    property int size: 13
    property string tone: porphyry ? "gilt" : "ink"
    signal clicked()

    implicitWidth: label.implicitWidth + 36
    implicitHeight: 38
    opacity: enabled ? 1 : 0.45
    activeFocusOnTab: true

    Keys.onReturnPressed: if (enabled) root.clicked()
    Keys.onSpacePressed: if (enabled) root.clicked()

    Slab {
        anchors.fill: parent
        anchors.topMargin: area.pressed ? 1 : 0
        anchors.bottomMargin: area.pressed ? -1 : 0
        porphyry: root.porphyry
        shadow: false

        Rectangle {
            anchors.fill: parent
            color: "white"
            opacity: !root.enabled ? 0 : area.containsMouse || root.activeFocus ? (root.porphyry ? 0.07 : 0.22) : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        Carved {
            id: label
            anchors.centerIn: parent
            text: root.text
            size: root.size
            spacing: 0.18
            tone: root.tone
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
