import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover

// TRIBVTVM: updates arriving from the provinces (APT, Flatpak and firmware),
// to be accepted all at once or one by one.
Pagina {
    id: page

    title: "TRIBVTVM"
    gloss: {
        switch (state) {
        case "progressing": return Theme.say("Tributum accipitur…", "Installing updates…");
        case "fetching": return Theme.say("Tributum e provinciis exspectatur…", "Looking for updates…");
        case "has-updates": return Theme.say("Tributum e provinciis advenit.", "Updates have arrived from the provinces.")
                                   + " · " + updates.updateSize;
        case "reboot": return Theme.say("Tributum post reditum accipietur.", "The updates finish when you restart.");
        default: return Theme.say("Nihil debetur. Omnia recentia sunt.", "Nothing is owed. Everything is up to date.");
        }
    }

    // Discover's C++ sets this for "plasma-discover --headless-update".
    property bool startHeadlessUpdate: false
    readonly property bool readyToUpdate: !tribute.isProgressing && !tribute.isFetching
    property bool armedReboot: false

    function considerHeadlessUpdate() {
        if (!startHeadlessUpdate || !readyToUpdate)
            return;
        if (updates.toUpdateCount > 0) {
            tribute.updateAll();
            app.quitWhenIdle();
        } else {
            app.restore();
        }
        startHeadlessUpdate = false;
    }
    onStartHeadlessUpdateChanged: considerHeadlessUpdate()
    onReadyToUpdateChanged: considerHeadlessUpdate()

    state: tribute.isProgressing ? "progressing"
         : tribute.isFetching ? "fetching"
         : updates.hasUpdates ? "has-updates"
         : tribute.needsReboot ? "reboot"
         : "uptodate"

    Discover.ResourcesUpdatesModel {
        id: tribute
        onPassiveMessage: message => page.forum.proclaim(message)
        onIsProgressingChanged: if (!isProgressing) prepare()
        Component.onCompleted: if (!isProgressing) prepare()
    }

    Discover.UpdateModel {
        id: updates
        backend: tribute
    }

    Timer {
        id: disarm
        interval: 4000
        onTriggered: page.armedReboot = false
    }

    ColumnLayout {
        anchors { fill: parent; leftMargin: 34; rightMargin: 34; topMargin: 20 }
        spacing: 14

        // The commands.
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Lapis {
                visible: page.state === "has-updates"
                enabled: page.readyToUpdate && updates.toUpdateCount > 0
                porphyry: true
                text: updates.toUpdateCount < updates.totalUpdatesCount
                      ? Theme.say("ACCIPE ELECTA", "UPDATE SELECTED") + " · " + Theme.num(updates.toUpdateCount)
                      : Theme.say("ACCIPE TRIBVTVM", "UPDATE ALL") + " · " + Theme.num(updates.toUpdateCount)
                onClicked: tribute.updateAll()
            }
            Lapis {
                visible: page.state === "has-updates" && updates.totalUpdatesCount > 1
                enabled: updates.toUpdateCount < updates.totalUpdatesCount
                text: Theme.say("OMNIA", "ALL")
                size: 11
                onClicked: updates.checkAll()
            }
            Lapis {
                visible: page.state === "has-updates" && updates.totalUpdatesCount > 1
                enabled: updates.toUpdateCount > 0
                text: Theme.say("NVLLA", "NONE")
                size: 11
                onClicked: updates.uncheckAll()
            }
            Lapis {
                visible: page.state === "progressing" && !!tribute.transaction && tribute.transaction.isCancellable
                text: Theme.say("OMITTE", "CANCEL")
                onClicked: tribute.transaction.cancel()
            }
            Lapis {
                visible: tribute.needsReboot && !tribute.isProgressing
                porphyry: true
                text: page.armedReboot ? Theme.say("CERTE?", "SURE?") : Theme.say("ITERVM", "RESTART")
                onClicked: {
                    if (!page.armedReboot) {
                        page.armedReboot = true;
                        disarm.restart();
                    } else {
                        app.rebootNow();
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Lapis {
                visible: page.state !== "progressing"
                enabled: Discover.ResourcesModel.updateAction.enabled && !tribute.isFetching
                text: Theme.say("RECENSE", "CHECK AGAIN")
                size: 11
                onClicked: Discover.ResourcesModel.updateAction.trigger()
            }
        }

        // Progress, while fetching or paying.
        Niche {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            visible: page.state === "fetching" || page.state === "progressing"
            readonly property int amount: page.state === "fetching" ? Discover.ResourcesModel.fetchingUpdatesProgress
                                        : (tribute.transaction ? tribute.transaction.progress : 0)
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 4 }
                width: Math.max(0, (parent.width - 8) * Math.min(1, parent.amount / 100))
                color: Theme.giltDeep
                opacity: 0.85
                Behavior on width { NumberAnimation { duration: 300 } }
            }
            Carved {
                anchors.centerIn: parent
                text: page.state === "fetching" ? Discover.ResourcesModel.remainingDescription
                    : (tribute.transaction && tribute.transaction.remainingTimeString !== ""
                       ? tribute.transaction.remainingTimeString : Theme.num(parent.amount) + " / C")
                family: Theme.serif
                size: 15
                weight: Font.Medium
                italic: true
            }
        }

        // Errors from the last attempt.
        Repeater {
            model: tribute.errorMessages
            delegate: Slab {
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredHeight: errorText.implicitHeight + 24
                porphyry: true
                shadow: false
                Carved {
                    id: errorText
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
                    text: Theme.plain(modelData)
                    family: Theme.serif
                    size: 15
                    weight: Font.Medium
                    tone: "gilt"
                    wrapMode: Text.Wrap
                    maximumLineCount: 8
                }
            }
        }

        // The tribute, item by item.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors { fill: parent; rightMargin: 14 }
                clip: true
                visible: page.state === "has-updates" || page.state === "progressing"
                model: updates
                boundsBehavior: Flickable.StopAtBounds
                spacing: 8

                section.property: "section"
                section.delegate: Item {
                    required property string section
                    width: list.width
                    height: 40
                    Carved {
                        anchors { left: parent.left; bottom: parent.bottom; bottomMargin: 10 }
                        text: Theme.stall(section) + (Theme.lingua === "en" ? "" : "  ·  " + section)
                        size: 13
                        spacing: 0.25
                        tone: "red"
                    }
                }

                delegate: Slab {
                    id: item
                    required property var model
                    required property int index
                    readonly property bool done: model.resourceStateIsDone
                    readonly property bool open: model.extended
                    shadow: false
                    width: list.width
                    height: 76 + (open ? notes.implicitHeight + 20 : 0)
                    opacity: done ? 0.55 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            item.model.extended = !item.open;
                            if (!item.open)
                                updates.fetchUpdateDetails(item.index);
                        }
                    }

                    RowLayout {
                        id: line
                        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 14; rightMargin: 18 }
                        height: 76
                        spacing: 14

                        // The tick box, cut into the stone.
                        Niche {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            opacity: tribute.isProgressing ? 0.5 : 1
                            Carved {
                                anchors.centerIn: parent
                                visible: item.model.checked === Qt.Checked
                                text: "✓"
                                family: Theme.serif
                                size: 22
                                tone: "red"
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !tribute.isProgressing
                                cursorShape: Qt.PointingHandCursor
                                onClicked: item.model.checked = (item.model.checked === Qt.Checked ? Qt.Unchecked : Qt.Checked)
                            }
                        }

                        AppIcon {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            resourceIcon: item.model.decoration
                            name: item.model.display || ""
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Carved {
                                Layout.fillWidth: true
                                text: item.model.display || ""
                                size: 15
                                weight: Font.Bold
                                elide: Text.ElideRight
                            }
                            Gloss {
                                Layout.fillWidth: true
                                text: item.model.resource ? Theme.plain(item.model.resource.upgradeText) : ""
                                size: 15
                                tone: "ink"
                                elide: Text.ElideRight
                            }
                        }

                        Badge {
                            resource: item.model.resource
                        }

                        // Per-item progress while paying, otherwise the size.
                        Item {
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 26
                            Carved {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                visible: !tribute.isProgressing
                                text: item.model.size || ""
                                family: Theme.serif
                                size: 15
                                weight: Font.Medium
                                tone: "faint"
                            }
                            Niche {
                                anchors.fill: parent
                                visible: tribute.isProgressing && !item.done
                                Rectangle {
                                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 3 }
                                    width: Math.max(0, (parent.width - 6) * Math.min(1, (item.model.resourceProgress || 0) / 100))
                                    color: Theme.giltDeep
                                }
                            }
                            Carved {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                visible: item.done
                                text: Theme.say("FACTVM", "DONE")
                                size: 11
                                spacing: 0.2
                                tone: "red"
                            }
                        }
                    }

                    // The changelog, when opened.
                    Text {
                        id: notes
                        visible: item.open
                        anchors { left: parent.left; right: parent.right; top: line.bottom; leftMargin: 72; rightMargin: 24 }
                        text: item.model.changelog ? item.model.changelog : Theme.say("<i>Annales quaeruntur…</i>", "<i>Fetching the changelog…</i>")
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        font.family: Theme.serif
                        font.pixelSize: 15
                        color: Theme.ink
                        linkColor: Theme.red
                        style: Text.Sunken
                        styleColor: Qt.rgba(1, 1, 1, 0.75)
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
                footer: Item { width: 1; height: 24 }
            }

            Rail {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom; bottomMargin: 20 }
                flickable: list
                visible: list.visible && ratio < 0.999
            }

            // All paid up.
            ColumnLayout {
                anchors.centerIn: parent
                visible: !list.visible
                spacing: 10
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: Theme.asset("emblem@2x.png")
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 140
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    opacity: 0.85
                }
                Carved {
                    Layout.alignment: Qt.AlignHCenter
                    text: page.state === "fetching" ? Theme.say("EXSPECTA…", "ONE MOMENT…")
                        : page.state === "reboot" ? Theme.say("REDI IN VRBEM", "RESTART TO FINISH")
                        : Theme.say("NIHIL DEBETVR", "NOTHING IS OWED")
                    size: 24
                    spacing: 0.24
                }
                Gloss {
                    Layout.alignment: Qt.AlignHCenter
                    visible: page.state !== "fetching" && tribute.lastUpdate.getTime && !isNaN(tribute.lastUpdate.getTime())
                    text: Theme.say("Ultima recensio: ", "Last checked: ") + Qt.formatDateTime(tribute.lastUpdate, "d MMMM yyyy, hh:mm")
                    size: 16
                }
            }
        }
    }
}
