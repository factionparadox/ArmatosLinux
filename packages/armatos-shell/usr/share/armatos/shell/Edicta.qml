import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Edicta: notifications, posted as small steles at the top right.
// SILENTIUM keeps them off the screen (critical ones still come through).
Scope {
    id: edicta

    property var posted: []          // notifications currently shown

    function post(n) {
        posted = posted.concat([n]);
    }
    function withdraw(n) {
        posted = posted.filter(p => p !== n);
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => edicta.withdraw(n));
            if (!Settings.silentium || n.urgency === NotificationUrgency.Critical)
                edicta.post(n);
        }
    }

    PanelWindow {
        id: win
        visible: edicta.posted.length > 0
        screen: Shell.focusedScreen()
        anchors { top: true; right: true }
        margins { top: 8; right: 14 }
        implicitWidth: 400
        implicitHeight: stack.implicitHeight + 30
        exclusionMode: ExclusionMode.Normal
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "armatos-edicta"

        Column {
            id: stack
            width: 380
            spacing: 14

            Repeater {
                model: edicta.posted

                Slab {
                    id: stele
                    required property var modelData
                    readonly property var n: modelData
                    readonly property bool critical: n.urgency === NotificationUrgency.Critical
                    moulding: critical
                    width: 380
                    height: body.implicitHeight + (critical ? Theme.mouldingHeight : 0) + 28

                    Timer {
                        running: !stele.critical && !hover.containsMouse
                        interval: stele.n.expireTimeout > 0 ? stele.n.expireTimeout : 7000
                        onTriggered: edicta.withdraw(stele.n)
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                stele.n.dismiss();
                                return;
                            }
                            const def = stele.n.actions.find(a => a.identifier === "default");
                            if (def)
                                def.invoke();
                            else
                                edicta.withdraw(stele.n);
                        }
                    }

                    RowLayout {
                        id: body
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                        spacing: 12

                        IconImage {
                            Layout.alignment: Qt.AlignTop
                            visible: source != ""
                            implicitSize: 40
                            source: stele.n.image !== "" ? stele.n.image
                                  : stele.n.appIcon !== "" ? Quickshell.iconPath(stele.n.appIcon, true)
                                  : ""
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Carved {
                                Layout.fillWidth: true
                                text: "EDICTVM · " + (stele.n.appName || "IMPERIVM").toUpperCase()
                                size: 10
                                spacing: 0.2
                                tone: "red"
                                elide: Text.ElideRight
                            }
                            Carved {
                                Layout.fillWidth: true
                                text: stele.n.summary
                                size: 15
                                weight: Font.Bold
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                            Carved {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: stele.n.body
                                family: Theme.serif
                                size: 16
                                weight: Font.Medium
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                visible: stele.n.actions.length > 0
                                spacing: 8

                                Repeater {
                                    model: stele.n.actions.filter(a => a.identifier !== "default")

                                    Niche {
                                        required property var modelData
                                        width: actionText.implicitWidth + 20
                                        height: 26
                                        Carved {
                                            id: actionText
                                            anchors.centerIn: parent
                                            text: modelData.text.toUpperCase()
                                            size: 11
                                            spacing: 0.1
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: modelData.invoke()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
