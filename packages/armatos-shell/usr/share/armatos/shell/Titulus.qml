import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray

// The Titulus: the inscription band along the top of each screen.
// Eagle (launcher) · workspaces I-IX · window title | time and Roman date |
// tray · RETE SONUS LUX VIS · VALE
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.mouldingHeight + 14     // room for the cast shadow
    exclusiveZone: Theme.barHeight + Theme.mouldingHeight
    color: "transparent"
    WlrLayershell.namespace: "armatos-titulus"

    // If Mango drops the surface (its output went away and came back, as
    // on a VT switch), raise it again rather than leave the screen bare.
    onVisibleChanged: if (!visible) revive.restart()
    Timer {
        id: revive
        interval: 1500
        onTriggered: bar.visible = true
    }
    WlrLayershell.layer: WlrLayer.Top
    mask: Region { item: band }

    readonly property var tags: Mango.tagsFor(bar.screen ? bar.screen.name : "")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        id: band
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.barHeight + Theme.mouldingHeight

        RectangularShadow {
            anchors.fill: moulding
            offset.y: 4
            blur: 10
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        Marble {
            id: face
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: Theme.barHeight

            Bevel {}

            // ---- Left: eagle, workspaces, title --------------------------------
            RowLayout {
                id: left
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                width: Math.max(0, centre.x - 24 - anchors.leftMargin)
                spacing: 12

                Niche {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 40

                    Image {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: Theme.asset("eagle.png")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        opacity: eagleArea.containsMouse ? 1.0 : 0.92
                    }
                    MouseArea {
                        id: eagleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Shell.toggleLauncher(bar.screen)
                    }
                }

                // Workspaces I-IX
                Row {
                    id: workspaces
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Repeater {
                        model: 9

                        Row {
                            id: slot
                            required property int index
                            readonly property var tag: bar.tags.length > index ? bar.tags[index] : null
                            readonly property bool active: tag !== null && tag.is_active
                            readonly property bool occupied: tag !== null && tag.client_count > 0
                            readonly property bool urgent: tag !== null && tag.is_urgent

                            Carved {
                                visible: slot.index > 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: "·"
                                size: 14
                            }

                            Item {
                                width: label.implicitWidth + (slot.active ? 16 : 6)
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter

                                Niche {
                                    anchors.fill: parent
                                    visible: slot.active
                                }
                                Carved {
                                    id: label
                                    anchors.centerIn: parent
                                    text: Theme.roman(slot.index + 1)
                                    size: 15
                                    weight: slot.active || slot.occupied || slot.urgent ? Font.Black : Font.DemiBold
                                    tone: slot.active || slot.urgent || hover.containsMouse ? "red"
                                        : slot.occupied ? "ink" : "faint"
                                }
                                MouseArea {
                                    id: hover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Mango.view(slot.index + 1)
                                }
                            }
                        }
                    }

                    WheelHandler {
                        onWheel: event => Mango.dispatch(event.angleDelta.y > 0 ? "viewtoleft" : "viewtoright")
                    }
                }

                Carved {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.alignment: Qt.AlignVCenter
                    text: Mango.title
                    family: Theme.serif
                    size: 16
                    weight: Font.Medium
                    italic: true
                    elide: Text.ElideRight
                }
            }

            // ---- Centre: the hour and the Roman date ---------------------------------
            Row {
                id: centre
                anchors.centerIn: parent
                spacing: 12

                Carved {
                    text: Qt.formatTime(clock.date, "HH:mm")
                    size: 19
                    spacing: 0.04
                }
                Carved {
                    text: Theme.dateLine(clock.date)
                    size: 13
                    weight: Font.Bold
                    tone: "red"
                    spacing: 0.1
                    y: 6
                }
            }

            // ---- Right: tray, readings, VALE ------------------------------------------
            RowLayout {
                id: right
                anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                spacing: 10

                Niche {
                    visible: SystemTray.items.values.length > 0
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: trayRow.implicitWidth + 16

                    Row {
                        id: trayRow
                        anchors.centerIn: parent
                        spacing: 8

                        Repeater {
                            model: SystemTray.items

                            IconImage {
                                id: trayIcon
                                required property var modelData
                                implicitSize: 16
                                source: modelData.icon
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        const item = trayIcon.modelData;
                                        if (mouse.button === Qt.MiddleButton)
                                            item.secondaryActivate();
                                        else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                                            if (item.hasMenu) {
                                                const p = trayIcon.mapToItem(null, 0, trayIcon.height + 8);
                                                item.display(bar, p.x, p.y);
                                            }
                                        } else
                                            item.activate();
                                    }
                                }
                            }
                        }
                    }
                }

                Niche {
                    id: readings
                    Layout.preferredHeight: 34
                    Layout.preferredWidth: readingRow.implicitWidth + 12

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Shell.toggleTabula(bar.screen)
                    }

                    Row {
                        id: readingRow
                        anchors.centerIn: parent
                        spacing: 0

                        Reading {
                            label: "RETE"
                            value: Indicia.rete.length > 14 ? Indicia.rete.slice(0, 13).toUpperCase() + "…" : Indicia.rete.toUpperCase()
                        }
                        Dot { visible: Indicia.hasSink }
                        Reading {
                            visible: Indicia.hasSink
                            label: "SONUS"
                            value: Indicia.muted ? Theme.say("TACET", "MUTE") : Theme.num(Indicia.sonus)
                            onScrolled: up => Indicia.setSonus(Indicia.sonus + (up ? 5 : -5))
                        }
                        Dot { visible: Indicia.hasBacklight }
                        Reading {
                            visible: Indicia.hasBacklight
                            label: "LUX"
                            value: Theme.num(Indicia.lux)
                            onScrolled: up => Indicia.setLux(Indicia.lux + (up ? 5 : -5))
                        }
                        Dot { visible: Indicia.hasBattery }
                        Reading {
                            visible: Indicia.hasBattery
                            label: "VIS"
                            value: Theme.num(Indicia.vis) + (Indicia.charging ? " +" : "")
                            warn: Indicia.onBattery && Indicia.vis < 15
                        }
                    }
                }

                // VALE: the porphyry power button
                Slab {
                    porphyry: true
                    shadow: false
                    Layout.preferredHeight: 38
                    Layout.preferredWidth: valeText.implicitWidth + 28

                    Carved {
                        id: valeText
                        anchors.centerIn: parent
                        text: "VALE"
                        size: 13
                        spacing: 0.2
                        tone: "gilt"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Shell.toggleVale(bar.screen)
                    }
                }
            }
        }

        Moulding {
            id: moulding
            anchors { left: parent.left; right: parent.right; top: face.bottom }
        }
    }

    component Dot: Carved {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        text: "·"
        size: 14
    }

    component Reading: Item {
        id: reading
        property string label
        property string value
        property bool warn: false
        signal scrolled(bool up)

        implicitWidth: readingLabel.implicitWidth + readingValue.implicitWidth + 15
        implicitHeight: 24

        Carved {
            id: readingLabel
            x: 5
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            text: reading.label
            size: 11
            weight: Font.Bold
            spacing: 0.14
            tone: "red"
        }
        Carved {
            id: readingValue
            anchors { left: readingLabel.right; leftMargin: 5; verticalCenter: parent.verticalCenter }
            text: reading.value
            size: 14
            tone: reading.warn ? "red" : "ink"
        }
        WheelHandler {
            onWheel: event => reading.scrolled(event.angleDelta.y > 0)
        }
    }
}
