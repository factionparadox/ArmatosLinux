import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// "Ave, Imperator. Quid imperas?" The launcher: a marble tablet over the
// blurred city. Type to search; Enter summons (ARCESSE), Esc dismisses.
PanelWindow {
    id: win

    visible: Shell.launcher
    screen: Shell.screen ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Qt.rgba(0.06, 0.03, 0.02, 0.38)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "armatos-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property int selected: 0
    readonly property int maxResults: 7

    // Entries that are plumbing rather than places to go. (Colonia stands in
    // for Calamares' own "Install System".)
    readonly property var hidden: ["calamares", "io.calamares.calamares", "foot-server", "footclient",
                                   "info", "thunar-bulk-rename", "org.quickshell"]
    function shown(a) {
        return !a.noDisplay && !hidden.includes(a.id) && !a.id.startsWith("python");
    }

    // Search the desktop entries: names first, then other words, then
    // descriptions. With nothing typed, everything in alphabetical order.
    readonly property var results: {
        const q = query.text.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(a => win.shown(a));
        if (q === "")
            return apps.slice().sort((a, b) => a.name.localeCompare(b.name)).slice(0, maxResults);
        const scored = [];
        for (const a of apps) {
            const name = a.name.toLowerCase();
            let score = -1;
            if (name.startsWith(q))
                score = 0;
            else if (name.split(/\s+/).some(w => w.startsWith(q)))
                score = 1;
            else if (name.includes(q))
                score = 2;
            else if ((a.genericName || "").toLowerCase().includes(q) || a.keywords.some(k => k.toLowerCase().includes(q)))
                score = 3;
            else if ((a.comment || "").toLowerCase().includes(q))
                score = 4;
            if (score >= 0)
                scored.push([score, a]);
        }
        scored.sort((x, y) => x[0] - y[0] || x[1].name.localeCompare(y[1].name));
        return scored.slice(0, maxResults).map(s => s[1]);
    }

    onResultsChanged: selected = 0
    onVisibleChanged: {
        if (visible) {
            query.text = "";
            selected = 0;
            query.forceActiveFocus();
        }
    }

    function summon(app) {
        if (!app)
            return;
        if (app.runInTerminal)
            Quickshell.execDetached(["foot", "--"].concat(app.command));
        else
            app.execute();
        Shell.launcher = false;
    }

    // Click outside the tablet to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: Shell.launcher = false
    }

    Slab {
        id: tablet
        moulding: true
        width: Math.min(640, win.width - 80)
        height: body.implicitHeight + Theme.mouldingHeight * 2 + 48
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(Theme.barHeight + 40, win.height * 0.16)

        MouseArea { anchors.fill: parent }      // clicks on the tablet stay on it

        Moulding {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        }

        ColumnLayout {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 30; topMargin: 22 }
            spacing: 16

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                source: Theme.asset("eagle.png")
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Carved {
                Layout.alignment: Qt.AlignHCenter
                text: Theme.say("AVE · IMPERATOR · QVID IMPERAS", "HAIL · IMPERATOR · WHAT DO YOU COMMAND")
                size: 19
                spacing: 0.14
            }

            Niche {
                Layout.fillWidth: true
                Layout.preferredHeight: 50

                TextInput {
                    id: query
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.serif
                    font.pixelSize: 22
                    font.weight: Font.Medium
                    color: Theme.ink
                    selectionColor: Theme.red
                    selectedTextColor: "#F4EDE2"
                    clip: true
                    focus: true

                    Keys.onEscapePressed: Shell.launcher = false
                    Keys.onReturnPressed: win.summon(win.results[win.selected])
                    Keys.onEnterPressed: win.summon(win.results[win.selected])
                    Keys.onUpPressed: win.selected = Math.max(0, win.selected - 1)
                    Keys.onDownPressed: win.selected = Math.min(win.results.length - 1, win.selected + 1)
                    Keys.onTabPressed: win.selected = (win.selected + 1) % Math.max(1, win.results.length)
                }
                Carved {
                    visible: query.text === ""
                    anchors { left: parent.left; leftMargin: 15; verticalCenter: parent.verticalCenter }
                    text: Theme.say("Quaere inter copias…", "Search apps…")
                    family: Theme.serif
                    size: 21
                    weight: Font.Normal
                    italic: true
                    tone: "faint"
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: win.results

                    Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool chosen: index === win.selected
                        width: parent.width
                        height: 58

                        Niche {
                            anchors.fill: parent
                            visible: row.chosen
                        }

                        Carved {
                            id: numeral
                            x: 12
                            width: 44
                            anchors.verticalCenter: parent.verticalCenter
                            text: Theme.roman(row.index + 1) + "."
                            size: 15
                            tone: row.chosen ? "red" : "ink"
                        }
                        Column {
                            anchors { left: numeral.right; leftMargin: 8; right: hint.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            spacing: 1

                            Carved {
                                width: parent.width
                                text: row.modelData.name.toUpperCase()
                                size: 16
                                spacing: 0.08
                                elide: Text.ElideRight
                            }
                            Carved {
                                width: parent.width
                                visible: text !== ""
                                text: row.modelData.comment || row.modelData.genericName || ""
                                family: Theme.serif
                                size: 16
                                weight: Font.Medium
                                italic: true
                                elide: Text.ElideRight
                            }
                        }
                        Carved {
                            id: hint
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            visible: row.chosen
                            text: "ARCESSE ↵"
                            size: 11
                            spacing: 0.16
                            tone: "red"
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.selected = row.index
                            onClicked: win.summon(row.modelData)
                        }
                    }
                }

                Carved {
                    visible: win.results.length === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Theme.say("Nemo miles hoc nomine respondet.", "No soldier answers to that name.")
                    family: Theme.serif
                    size: 18
                    weight: Font.Medium
                    italic: true
                }
            }

            Carved {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                text: Theme.say("↑↓ ELIGE · ↵ ARCESSE · ESC DIMITTE", "↑↓ CHOOSE · ↵ SUMMON · ESC DISMISS")
                size: 11
                spacing: 0.16
            }
        }
    }
}
