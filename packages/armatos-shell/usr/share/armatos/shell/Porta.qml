import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// Porta, the city gate: the lock screen. "Portae clausae sunt."
// Opens to the watchword, or to a finger on the reader if one is enrolled;
// both are listened for at once.
Scope {
    id: porta

    property string typed: ""
    property string pending: ""          // watchword given before PAM asked for it
    property string notice: ""
    property bool failed: false
    property bool fingerprint: false
    property bool asked: false           // PAM is waiting for the watchword right now

    function open() {
        asked = false;
        pass.abort();
        finger.abort();
        typed = "";
        pending = "";
        notice = "";
        failed = false;
        Shell.locked = false;
    }

    function submit() {
        if (typed === "")
            return;
        failed = false;
        notice = Theme.say("Auctoritas quaeritur…", "Checking…");
        if (asked) {
            asked = false;
            pass.respond(typed);
        } else {
            pending = typed;
            if (!pass.active)
                pass.start();
        }
        typed = "";
    }

    Connections {
        target: Shell
        function onLockedChanged() {
            if (Shell.locked) {
                porta.typed = "";
                porta.notice = "";
                porta.failed = false;
                pass.start();
                if (porta.fingerprint)
                    finger.start();
            }
        }
    }

    // Is there a reader with a print enrolled for us?
    Process {
        running: true
        command: ["fprintd-list", Quickshell.env("USER") || ""]
        stdout: StdioCollector {
            onStreamFinished: porta.fingerprint = /#\d+:/.test(text)
        }
    }

    PamContext {
        id: pass
        configDirectory: "pam"
        config: "porta"
        onPamMessage: {
            if (!responseRequired)
                return;
            if (porta.pending !== "") {
                respond(porta.pending);
                porta.pending = "";
            } else {
                porta.asked = true;
            }
        }
        onCompleted: result => {
            porta.asked = false;
            if (result === PamResult.Success) {
                porta.open();
            } else {
                porta.failed = true;
                porta.notice = Theme.say("Senatus petitionem tuam negat.", "The Senate denies your petition.");
                restartPass.restart();
            }
        }
    }
    Timer { id: restartPass; interval: 300; onTriggered: if (Shell.locked && !pass.active) pass.start() }

    PamContext {
        id: finger
        configDirectory: "pam"
        config: "digitus"
        onCompleted: result => {
            if (result === PamResult.Success)
                porta.open();
            else if (Shell.locked)
                restartFinger.restart();      // timed out or misread: listen again
        }
    }
    Timer { id: restartFinger; interval: 1500; onTriggered: if (Shell.locked && !finger.active) finger.start() }

    WlSessionLock {
        id: lock
        locked: Shell.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.night

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Image {
                anchors.fill: parent
                source: Theme.asset("atlas-porta.jpg")
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        porta.submit();
                    } else if (event.key === Qt.Key_Backspace) {
                        porta.typed = porta.typed.slice(0, -1);
                    } else if (event.key === Qt.Key_Escape) {
                        porta.typed = "";
                    } else if (event.text !== "" && event.text.charCodeAt(0) >= 32) {
                        porta.typed += event.text;
                        porta.failed = false;
                    }
                    event.accepted = true;
                }
            }

            // The hour, carved large in gilt.
            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.14
                spacing: 6

                Carved {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatTime(clock.date, "HH:mm")
                    size: 96
                    spacing: 0.04
                    tone: "gilt"
                }
                Carved {
                    Layout.alignment: Qt.AlignHCenter
                    text: Theme.romanDate(clock.date) + "·" + Theme.roman(Theme.aucYear(clock.date))
                    size: 18
                    weight: Font.Bold
                    spacing: 0.16
                    tone: "gilt"
                }
            }

            // The gate tablet.
            Slab {
                id: gate
                moulding: true
                width: 520
                height: gateBody.implicitHeight + Theme.mouldingHeight * 2 + 52
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.42

                Moulding { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } }

                ColumnLayout {
                    id: gateBody
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 32; topMargin: 24 }
                    spacing: 14

                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        source: Theme.asset("eagle.png")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                    Carved {
                        Layout.alignment: Qt.AlignHCenter
                        text: Theme.say("PORTAE CLAVSAE SVNT", "THE GATES ARE SEALED")
                        size: 22
                        spacing: 0.18
                    }
                    Carved {
                        Layout.alignment: Qt.AlignHCenter
                        visible: porta.fingerprint
                        text: Theme.say("DIGITVM ADMOVE", "TOUCH THE READER")
                        size: 13
                        spacing: 0.2
                        tone: "red"
                    }
                    Carved {
                        Layout.alignment: Qt.AlignHCenter
                        text: porta.fingerprint
                            ? Theme.say("digitum legenti admove, aut tesseram da", "touch the fingerprint reader, or give the watchword")
                            : Theme.say("tesseram da", "give the watchword")
                        family: Theme.serif
                        size: 17
                        weight: Font.Medium
                        italic: true
                    }

                    // The watchword, shown as carved points.
                    Niche {
                        id: field
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50

                        transform: Translate { id: shake; x: 0 }

                        Carved {
                            anchors.centerIn: parent
                            visible: porta.typed !== ""
                            text: "•".repeat(Math.min(porta.typed.length, 28))
                            family: Theme.serif
                            size: 22
                            spacing: 0.2
                        }
                        Carved {
                            anchors.centerIn: parent
                            visible: porta.typed === ""
                            text: Theme.say("tessera", "watchword")
                            family: Theme.serif
                            size: 19
                            weight: Font.Normal
                            italic: true
                            tone: "faint"
                        }
                    }

                    Carved {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 20
                        text: porta.notice
                        family: Theme.serif
                        size: 16
                        weight: Font.Medium
                        italic: true
                        tone: porta.failed ? "red" : "ink"
                    }
                }

                SequentialAnimation {
                    running: porta.failed
                    NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                    NumberAnimation { target: shake; property: "x"; to: 10; duration: 80 }
                    NumberAnimation { target: shake; property: "x"; to: -6; duration: 70 }
                    NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
                }
            }

            // Readings along the foot of the gate.
            Carved {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 36 }
                text: (Indicia.hasBattery ? "VIS " + Theme.num(Indicia.vis) + "  ·  " : "") + "RETE " + Indicia.rete.toUpperCase()
                size: 13
                spacing: 0.16
                tone: "gilt"
            }
        }
    }
}
