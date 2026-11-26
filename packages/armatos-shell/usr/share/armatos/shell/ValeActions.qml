import QtQuick
import QtQuick.Layouts
import Quickshell

// Farewells: PORTA lock · SOMNVS suspend · EXI log out · ITERVM restart ·
// VALE shut down. The last three ask "CERTE?" (surely?) before acting.
ColumnLayout {
    id: root
    spacing: 10

    property string armed: ""

    function act(name) {
        if (["exi", "iterum", "vale"].includes(name) && armed !== name) {
            armed = name;
            disarm.restart();
            return;
        }
        armed = "";
        Shell.closeAll();
        switch (name) {
        case "porta": Shell.lock(); break;
        case "somnus": Shell.sleep(); break;
        case "exi": Mango.quit(); break;
        case "iterum": Quickshell.execDetached(["systemctl", "reboot"]); break;
        case "vale": Quickshell.execDetached(["systemctl", "poweroff"]); break;
        }
    }

    Timer { id: disarm; interval: 4000; onTriggered: root.armed = "" }

    component Farewell: Item {
        id: f
        property string key
        property string label
        property string detail
        implicitWidth: Math.max(l.implicitWidth, d.implicitWidth)
        implicitHeight: l.implicitHeight + d.implicitHeight + 2
        Carved {
            id: l
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.armed === f.key ? "CERTE?" : f.label
            size: 13
            spacing: 0.1
            tone: root.armed === f.key || area.containsMouse ? "red" : "ink"
        }
        Carved {
            id: d
            anchors { horizontalCenter: parent.horizontalCenter; top: l.bottom; topMargin: 2 }
            text: f.detail
            family: Theme.serif
            size: 14
            weight: Font.Medium
            italic: true
        }
        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.act(f.key)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0
        Farewell { Layout.fillWidth: true; key: "porta"; label: "PORTA"; detail: Theme.say("claude", "lock") }
        Farewell { Layout.fillWidth: true; key: "somnus"; label: "SOMNVS"; detail: Theme.say("dormi", "suspend") }
        Farewell { Layout.fillWidth: true; key: "exi"; label: "EXI"; detail: Theme.say("discede", "log out") }
        Farewell { Layout.fillWidth: true; key: "iterum"; label: "ITERVM"; detail: Theme.say("renascere", "restart") }
    }

    Slab {
        porphyry: true
        shadow: false
        Layout.fillWidth: true
        Layout.preferredHeight: 46

        Row {
            anchors.centerIn: parent
            spacing: 12
            Carved {
                text: root.armed === "vale" ? "CERTE?" : "VALE"
                size: 16
                spacing: 0.24
                tone: "gilt"
            }
            Carved {
                y: 2
                text: Theme.say("exstingue", "shut down")
                family: Theme.serif
                size: 15
                weight: Font.Medium
                italic: true
                tone: "gilt"
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.act("vale")
        }
    }
}
