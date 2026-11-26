import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// The VALE button's tablet: just the farewells.
PanelWindow {
    id: win
    visible: Shell.vale
    screen: Shell.screen ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "armatos-vale"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea { anchors.fill: parent; onClicked: Shell.vale = false }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Shell.vale = false
    }

    Slab {
        moulding: true
        width: 420
        height: col.implicitHeight + Theme.mouldingHeight + 40
        anchors { right: parent.right; top: parent.top; rightMargin: 14; topMargin: 8 }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 22; topMargin: 18 }
            spacing: 14

            Carved {
                Layout.alignment: Qt.AlignHCenter
                text: Theme.say("VALE, IMPERATOR", "FAREWELL, IMPERATOR")
                size: 18
                spacing: 0.18
            }
            ValeActions { Layout.fillWidth: true }
        }
    }
}
