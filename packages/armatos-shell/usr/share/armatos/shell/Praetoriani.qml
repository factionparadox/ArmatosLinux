import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit

// The Praetorians at the Senate door: the polkit agent. When a program asks
// for authority (installing, mounting, changing the system), this tablet
// asks for the watchword. "Auctoritas Senatus quaeritur…"
Scope {
    id: guard

    PolkitAgent {
        id: agent
    }

    readonly property var flow: agent.flow

    PanelWindow {
        id: win
        visible: agent.isActive && guard.flow !== null
        screen: Shell.focusedScreen()
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Qt.rgba(0.06, 0.03, 0.02, 0.5)
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "armatos-praetoriani"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: {
            answer.text = "";
            if (visible)
                answer.forceActiveFocus();
        }

        function grant() {
            if (guard.flow && guard.flow.isResponseRequired) {
                guard.flow.submit(answer.text);
                answer.text = "";
            }
        }
        function deny() {
            if (guard.flow)
                guard.flow.cancelAuthenticationRequest();
        }

        Slab {
            moulding: true
            width: Math.min(560, win.width - 60)
            height: body.implicitHeight + Theme.mouldingHeight + 48
            anchors.centerIn: parent

            ColumnLayout {
                id: body
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 30; topMargin: 22 }
                spacing: 12

                Carved {
                    Layout.alignment: Qt.AlignHCenter
                    text: Theme.say("AVCTORITAS SENATVS QVAERITVR", "THE SENATE'S AUTHORITY IS SOUGHT")
                    size: 16
                    spacing: 0.16
                    tone: "red"
                }
                Carved {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: guard.flow ? guard.flow.message : ""
                    family: Theme.serif
                    size: 18
                    weight: Font.Medium
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                }
                Carved {
                    Layout.alignment: Qt.AlignHCenter
                    visible: guard.flow !== null && guard.flow.selectedIdentity !== null
                    text: guard.flow && guard.flow.selectedIdentity
                        ? Theme.say("ut ", "as ") + guard.flow.selectedIdentity.displayName : ""
                    family: Theme.serif
                    size: 16
                    weight: Font.Normal
                    italic: true
                }

                Niche {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    TextInput {
                        id: answer
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: guard.flow && guard.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        font.family: Theme.serif
                        font.pixelSize: 20
                        color: Theme.ink
                        clip: true
                        Keys.onReturnPressed: win.grant()
                        Keys.onEnterPressed: win.grant()
                        Keys.onEscapePressed: win.deny()
                    }
                    Carved {
                        visible: answer.text === ""
                        anchors { left: parent.left; leftMargin: 15; verticalCenter: parent.verticalCenter }
                        text: Theme.say("tessera", "watchword")
                        family: Theme.serif
                        size: 18
                        weight: Font.Normal
                        italic: true
                        tone: "faint"
                    }
                }

                Carved {
                    Layout.alignment: Qt.AlignHCenter
                    visible: text !== ""
                    text: guard.flow && guard.flow.failed
                        ? Theme.say("Senatus petitionem tuam negat.", "The Senate denies your petition.")
                        : (guard.flow ? guard.flow.supplementaryMessage : "")
                    family: Theme.serif
                    size: 16
                    weight: Font.Medium
                    italic: true
                    tone: "red"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Slab {
                        shadow: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        Carved { anchors.centerIn: parent; text: Theme.say("NEGA", "DENY"); size: 14; spacing: 0.2 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.deny() }
                    }
                    Slab {
                        porphyry: true
                        shadow: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        Carved { anchors.centerIn: parent; text: Theme.say("CONCEDE", "GRANT"); size: 14; spacing: 0.2; tone: "gilt" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.grant() }
                    }
                }
            }
        }
    }
}
