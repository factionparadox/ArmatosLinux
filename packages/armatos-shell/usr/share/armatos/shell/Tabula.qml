import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Mpris

// Tabula Imperii: the quick settings tablet, opened from the readings.
PanelWindow {
    id: win

    visible: Shell.tabula
    screen: Shell.screen ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "armatos-tabula"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property var asking: null            // the Wi-Fi network whose watchword we're asking for

    onVisibleChanged: {
        asking = null;
        if (Indicia.wifiDevice)
            Indicia.wifiDevice.scannerEnabled = visible;
    }

    MouseArea { anchors.fill: parent; onClicked: Shell.tabula = false }

    Slab {
        id: tablet
        moulding: true
        width: 460
        height: Math.min(win.height - 16, col.implicitHeight + Theme.mouldingHeight + 44)
        anchors { right: parent.right; top: parent.top; rightMargin: 14; topMargin: 8 }

        MouseArea { anchors.fill: parent }

        Flickable {
            anchors { fill: parent; margins: 26; topMargin: 20; bottomMargin: 20 }
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                width: parent.width
                spacing: 14

                Keys.onEscapePressed: Shell.tabula = false

                // ---- Title ---------------------------------------------------------
                Carved {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "TABVLA IMPERII"
                    size: 22
                    spacing: 0.2
                }
                Carved {
                    Layout.fillWidth: true
                    Layout.topMargin: -10
                    horizontalAlignment: Text.AlignHCenter
                    text: Indicia.hasBattery ? Indicia.visLine()
                        : Theme.romanDate(new Date()) + "·" + Theme.roman(Theme.aucYear(new Date()))
                    family: Indicia.hasBattery ? Theme.serif : Theme.caps
                    size: Indicia.hasBattery ? 16 : 12
                    weight: Indicia.hasBattery ? Font.Medium : Font.Bold
                    italic: Indicia.hasBattery
                    tone: Indicia.hasBattery ? "ink" : "red"
                }

                // ---- IMPERIA: the orders ------------------------------------------
                Rubric { Layout.fillWidth: true; text: "IMPERIA" }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Toggle {
                        label: "RETE"
                        on: Networking.wifiEnabled
                        detail: !Networking.wifiEnabled ? Theme.say("Wi-Fi exstinctum", "Wi-Fi off")
                              : Indicia.wifiNetwork ? "Wi-Fi · " + Indicia.wifiNetwork.name
                              : Indicia.wiredDevice ? Theme.say("filo coniunctum", "wired")
                              : Theme.say("Wi-Fi · quaerit", "Wi-Fi · searching")
                        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                    Toggle {
                        visible: win.adapter !== null
                        label: "BLUETOOTH"
                        on: win.adapter !== null && win.adapter.enabled
                        detail: {
                            if (!win.adapter || !win.adapter.enabled)
                                return Theme.say("exstinctum", "off");
                            const n = win.adapter.devices.values.filter(d => d.connected).length;
                            if (n === 0)
                                return Theme.say("nullum instrumentum", "no devices");
                            return Theme.say(Theme.roman(n) + " coniuncta", n === 1 ? "one device" : n + " devices");
                        }
                        onToggled: win.adapter.enabled = !win.adapter.enabled
                    }
                    Toggle {
                        label: "LUCERNA"
                        on: Settings.lucerna
                        detail: Theme.say("lumen nocturnum, ab occasu", "night light, from sunset")
                        onToggled: Settings.lucerna = !Settings.lucerna
                    }
                    Toggle {
                        label: "SILENTIUM"
                        on: Settings.silentium
                        detail: Theme.say("edicta tacent", "do not disturb")
                        onToggled: Settings.silentium = !Settings.silentium
                    }
                }

                // ---- CURSUS PUBLICUS: Wi-Fi networks --------------------------------
                Rubric {
                    Layout.fillWidth: true
                    visible: Indicia.wifiDevice !== null && Networking.wifiEnabled
                    text: "CURSUS PUBLICUS · WI-FI"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: Indicia.wifiDevice !== null && Networking.wifiEnabled
                    spacing: 0

                    Repeater {
                        model: {
                            if (!Indicia.wifiDevice)
                                return [];
                            const seen = {};
                            return Indicia.wifiDevice.networks.values
                                .filter(n => n.name !== "" && !seen[n.name] && (seen[n.name] = true))
                                .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
                                .slice(0, 6);
                        }

                        ColumnLayout {
                            id: net
                            required property var modelData
                            required property int index
                            readonly property bool open: modelData.security === WifiSecurityType.Open
                            Layout.fillWidth: true
                            spacing: 4

                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 28

                                Carved {
                                    id: netNum
                                    width: 30
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Theme.roman(net.index + 1) + "."
                                    size: 13
                                    tone: "red"
                                }
                                Carved {
                                    anchors { left: netNum.right; leftMargin: 6; right: netState.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                    text: net.modelData.name
                                    family: Theme.serif
                                    size: 16
                                    weight: net.modelData.connected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                    tone: netArea.containsMouse ? "red" : "ink"
                                }
                                Carved {
                                    id: netState
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    text: net.modelData.stateChanging ? Theme.say("iungitur…", "connecting…")
                                        : net.modelData.connected ? Theme.say("coniuncta", "connected")
                                        : net.modelData.known ? Theme.say("nota", "known")
                                        : net.open ? Theme.say("aperta", "open")
                                        : Theme.say("clausa", "locked")
                                    family: Theme.serif
                                    size: 15
                                    weight: Font.Normal
                                    italic: true
                                }
                                MouseArea {
                                    id: netArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const n = net.modelData;
                                        if (n.connected)
                                            return;
                                        if (n.known || net.open)
                                            n.connect();
                                        else
                                            win.asking = (win.asking === n ? null : n);
                                    }
                                }
                            }

                            // Watchword for a locked network
                            Niche {
                                visible: win.asking === net.modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36

                                TextInput {
                                    id: psk
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    font.family: Theme.serif
                                    font.pixelSize: 17
                                    color: Theme.ink
                                    clip: true
                                    onVisibleChanged: { text = ""; if (visible) forceActiveFocus(); }
                                    Keys.onReturnPressed: { net.modelData.connectWithPsk(text); win.asking = null; }
                                    Keys.onEscapePressed: win.asking = null
                                }
                                Carved {
                                    visible: psk.text === ""
                                    anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter }
                                    text: Theme.say("tessera, deinde ↵", "watchword, then ↵")
                                    family: Theme.serif
                                    size: 16
                                    weight: Font.Normal
                                    italic: true
                                    tone: "faint"
                                }
                            }
                        }
                    }
                }

                // ---- MENSURAE: the measures ------------------------------------------
                Rubric { Layout.fillWidth: true; text: "MENSURAE" }

                Measure {
                    label: "SONUS"
                    detail: Theme.say("vox", "volume")
                    value: Indicia.sonus
                    reading: Indicia.muted ? Theme.say("TACET", "MUTE") : Theme.num(Indicia.sonus)
                    available: Indicia.hasSink
                    onMoved: v => Indicia.setSonus(v)
                    onLabelClicked: Indicia.toggleMute()
                }
                Measure {
                    label: "LUX"
                    detail: Theme.say("claritas", "brightness")
                    value: Indicia.lux
                    reading: Theme.num(Indicia.lux)
                    available: Indicia.hasBacklight
                    onMoved: v => Indicia.setLux(v)
                }

                // Numerals and tongue
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 26
                    Carved {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Theme.say("Numeri", "Numerals")
                        family: Theme.serif
                        size: 16
                        weight: Font.Medium
                        italic: true
                    }
                    Choice {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        options: [["romani", "ROMANI"], ["arabici", "ARABICI"]]
                        current: Settings.numerals
                        onChosen: key => Settings.numerals = key
                    }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 26
                    Carved {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Theme.say("Lingua", "Language")
                        family: Theme.serif
                        size: 16
                        weight: Font.Medium
                        italic: true
                    }
                    Choice {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        options: [["la", "LATINE"], ["en", "ANGLICE"]]
                        current: Settings.lingua
                        onChosen: key => Settings.lingua = key
                    }
                }

                // ---- VIS: power profile --------------------------------------------------
                Rubric { Layout.fillWidth: true; text: Theme.say("VIS · RATIO", "VIS · POWER PROFILE") }
                Choice {
                    Layout.alignment: Qt.AlignHCenter
                    options: PowerProfiles.hasPerformanceProfile
                        ? [["0", "QVIES"], ["1", "AEQVVS"], ["2", "CELERITAS"]]
                        : [["0", "QVIES"], ["1", "AEQVVS"]]
                    current: String(PowerProfiles.profile)
                    onChosen: key => PowerProfiles.profile = parseInt(key)
                    size: 13
                }

                // ---- CANTVS: now playing -------------------------------------------------
                Rubric { Layout.fillWidth: true; visible: win.player !== null; text: Theme.say("CANTVS", "CANTVS · NOW PLAYING") }
                Item {
                    visible: win.player !== null
                    Layout.fillWidth: true
                    implicitHeight: 30
                    Carved {
                        id: prevBtn
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "‹"
                        size: 22
                        tone: prevArea.containsMouse ? "red" : "ink"
                        MouseArea { id: prevArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: win.player.previous() }
                    }
                    Carved {
                        anchors { left: prevBtn.right; right: nextBtn.left; margins: 12; verticalCenter: parent.verticalCenter }
                        horizontalAlignment: Text.AlignHCenter
                        text: win.player ? (win.player.trackTitle || win.player.identity) + (win.player.trackArtist ? " — " + win.player.trackArtist : "") : ""
                        family: Theme.serif
                        size: 16
                        weight: Font.Medium
                        italic: !(win.player && win.player.isPlaying)
                        elide: Text.ElideRight
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.player.togglePlaying() }
                    }
                    Carved {
                        id: nextBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: "›"
                        size: 22
                        tone: nextArea.containsMouse ? "red" : "ink"
                        MouseArea { id: nextArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: win.player.next() }
                    }
                }

                // ---- VALE ---------------------------------------------------------------
                Rubric { Layout.fillWidth: true; text: "VALE" }
                ValeActions { Layout.fillWidth: true }
            }
        }
    }

    // A labelled slider row.
    component Measure: ColumnLayout {
        id: m
        property string label
        property string detail
        property string reading
        property real value
        property bool available: true
        signal moved(real v)
        signal labelClicked()

        visible: available
        Layout.fillWidth: true
        spacing: 4

        Item {
            Layout.fillWidth: true
            implicitHeight: 22
            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                Carved {
                    text: m.label
                    size: 14
                    spacing: 0.08
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m.labelClicked() }
                }
                Carved {
                    y: 1
                    text: m.detail
                    family: Theme.serif
                    size: 15
                    weight: Font.Medium
                    italic: true
                }
            }
            Carved {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: m.reading
                size: 15
                tone: "red"
            }
        }
        Gradus {
            value: m.value
            onMoved: v => m.moved(v)
        }
    }

    // ROMANI · ARABICI style choice: the chosen word in red, others plain.
    component Choice: Row {
        id: c
        property var options: []
        property string current
        property int size: 12
        signal chosen(string key)
        spacing: 0

        Repeater {
            model: c.options
            Row {
                required property var modelData
                required property int index
                Carved {
                    visible: index > 0
                    text: " · "
                    size: c.size
                }
                Carved {
                    text: modelData[1]
                    size: c.size
                    spacing: 0.12
                    weight: c.current === modelData[0] ? Font.Black : Font.DemiBold
                    tone: c.current === modelData[0] ? "red" : (choiceArea.containsMouse ? "ink" : "faint")
                    MouseArea {
                        id: choiceArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: c.chosen(modelData[0])
                    }
                }
            }
        }
    }
}
