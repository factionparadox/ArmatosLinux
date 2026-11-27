import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover

// FONTES: where the goods come from. The APT archives, any Flatpak
// remotes (peregrina, a concession), and the firmware service.
Pagina {
    id: page
    title: "FONTES"
    gloss: Theme.say("Unde merces veniunt.", "Where the goods come from.")

    function backendTitle(backend) {
        if (!backend || !backend.resourcesBackend)
            return "";
        const name = backend.resourcesBackend.name;
        const shown = backend.resourcesBackend.displayName;
        if (name === "flatpak-backend")
            return "PEREGRINA · " + shown.toUpperCase();
        if (name === "fwupd-backend")
            return Theme.say("FERRAMENTA", "FIRMWARE") + " · " + shown.toUpperCase();
        return "APT · " + shown.toUpperCase();
    }

    // Backends not installed yet (Flatpak support, for instance) are add-ons
    // that extend Discover itself.
    Discover.ResourcesProxyModel {
        id: missing
        extending: "org.kde.discover.desktop"
        filterMinimumState: false
    }

    // The APT backend only reads its repository list when told the page is open.
    Component.onCompleted: Qt.callLater(Discover.SourcesModel.showingNow)

    ListView {
        id: list
        anchors { fill: parent; leftMargin: 34; rightMargin: 48; topMargin: 20 }
        clip: true
        model: Discover.SourcesModel
        boundsBehavior: Flickable.StopAtBounds
        spacing: 8

        section.property: "sourceName"
        section.delegate: Item {
            id: head
            required property string section
            readonly property var backend: Discover.SourcesModel.sourcesBackendByName(section)
            width: list.width
            height: headColumn.implicitHeight + 26

            Connections {
                target: head.backend
                function onPassiveMessage(message) {
                    page.forum.proclaim(message);
                }
                function onProceedRequest(title, description) {
                    page.forum.petition = { transaction: head.backend, title, description };
                }
            }

            ColumnLayout {
                id: headColumn
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 8 }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Carved {
                        Layout.fillWidth: true
                        text: page.backendTitle(head.backend)
                        size: 15
                        spacing: 0.2
                        tone: "red"
                        elide: Text.ElideRight
                    }
                    Repeater {
                        model: head.backend ? head.backend.actions : []
                        delegate: Lapis {
                            required property var modelData
                            visible: modelData.visible
                            enabled: modelData.enabled
                            porphyry: true
                            text: modelData.objectName === "flathub" ? Theme.say("ADDE FLATHVB", "ADD FLATHUB")
                                : (modelData.text || "").replace(/&/g, "").toUpperCase()
                            size: 11
                            implicitHeight: 32
                            onClicked: modelData.trigger()
                        }
                    }
                }
                Gloss {
                    Layout.fillWidth: true
                    visible: !!head.backend && head.backend.resourcesBackend && head.backend.resourcesBackend.name === "flatpak-backend"
                    text: Theme.say("Merces peregrinae leges Armatos ignorant. Utere tantum si nulla sarcina .deb exstat.",
                                    "Foreign goods ignore Armatos's laws. Use them only when no .deb exists.")
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
                // Adding a source by address, where the backend allows it.
                RowLayout {
                    Layout.fillWidth: true
                    visible: !!head.backend && head.backend.supportsAdding
                    spacing: 10
                    Niche {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        TextInput {
                            id: address
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.mono
                            font.pixelSize: 14
                            color: Theme.ink
                            clip: true
                            Keys.onReturnPressed: addButton.clicked()
                        }
                        Gloss {
                            visible: address.text === "" && !address.activeFocus
                            anchors { left: parent.left; leftMargin: 13; verticalCenter: parent.verticalCenter }
                            text: head.backend ? head.backend.idDescription : ""
                            size: 15
                        }
                    }
                    Lapis {
                        id: addButton
                        enabled: address.text.trim() !== ""
                        text: Theme.say("ADDE", "ADD")
                        size: 11
                        implicitHeight: 34
                        onClicked: {
                            if (head.backend.addSource(address.text.trim()))
                                address.text = "";
                        }
                    }
                }
            }
        }

        delegate: Slab {
            id: row
            required property var model
            required property int index
            readonly property bool on: model.checkState !== Qt.Unchecked
            readonly property bool checkable: (Discover.SourcesModel.flags(Discover.SourcesModel.index(index, 0)) & Qt.ItemIsUserCheckable) !== 0
            property bool armed: false
            // Flatpak's "-" stands for "no remotes yet"; the heading says enough.
            readonly property bool placeholder: !model.display || model.display === "-"
            shadow: false
            seed: Theme.hash(model.display)
            width: list.width
            height: placeholder ? 0 : 60
            visible: !placeholder
            opacity: model.enabled === false ? 0.5 : 1

            Timer {
                id: disarm
                interval: 3500
                onTriggered: row.armed = false
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 14

                Niche {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    opacity: row.checkable ? 1 : 0.4
                    Carved {
                        anchors.centerIn: parent
                        visible: row.on
                        text: "✓"
                        family: Theme.serif
                        size: 22
                        tone: "red"
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: row.checkable
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Discover.SourcesModel.setData(Discover.SourcesModel.index(row.index, 0),
                                                                 row.on ? Qt.Unchecked : Qt.Checked, Qt.CheckStateRole)
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Carved {
                        Layout.fillWidth: true
                        text: Theme.plain(row.model.display)
                        family: Theme.serif
                        size: 17
                        weight: Font.Medium
                        elide: Text.ElideMiddle
                    }
                    Gloss {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: Theme.plain(row.model.toolTip)
                        size: 14
                        elide: Text.ElideRight
                    }
                }
                Lapis {
                    visible: !!row.model.sourcesBackend && row.model.sourcesBackend.canFilterSources
                    text: Theme.say("MERCES", "CONTENTS")
                    size: 10
                    implicitHeight: 30
                    onClicked: page.forum.push("Merces", { originFilter: row.model.sourceId, allBackends: true, heading: (row.model.display || "").toUpperCase() })
                }
                Lapis {
                    visible: !!row.model.sourcesBackend && row.model.sourcesBackend.supportsAdding
                    porphyry: row.armed
                    text: row.armed ? Theme.say("CERTE?", "SURE?") : Theme.say("ABICE", "REMOVE")
                    size: 10
                    implicitHeight: 30
                    onClicked: {
                        if (!row.armed) {
                            row.armed = true;
                            disarm.restart();
                        } else {
                            row.model.sourcesBackend.removeSource(row.model.sourceId);
                        }
                    }
                }
            }
        }

        footer: ColumnLayout {
            width: list.width
            spacing: 8

            Item { Layout.preferredHeight: 18 }
            Carved {
                visible: missingRepeater.count > 0
                text: Theme.say("ADDITAMENTA FORI", "FORUM ADD-ONS")
                size: 15
                spacing: 0.2
                tone: "red"
            }
            Gloss {
                Layout.fillWidth: true
                visible: missingRepeater.count > 0
                text: Theme.say("Alia genera mercium quae Forum vendere potest.", "Other kinds of goods the Forum can sell, once added.")
                wrapMode: Text.Wrap
            }
            Repeater {
                id: missingRepeater
                model: missing
                delegate: Merx {
                    Layout.fillWidth: true
                    forum: page.forum
                    showEngine: true
                    // Snap support needs snapd, which Lex II banishes.
                    veto: !!application && (application.appstreamId.indexOf("snap") >= 0 || application.packageName.indexOf("snap") >= 0)
                }
            }
            Item { Layout.preferredHeight: 24 }
        }
    }

    Rail {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: 8; rightMargin: 20 }
        flickable: list
    }
}
