import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover

// What the Imperator already owns, from every source.
Pagina {
    id: page
    title: "POSSESSA"
    gloss: {
        if (owned.busy)
            return Theme.say("Possessa numerantur…", "Counting what you own…");
        const n = owned.count && owned.count.valid ? owned.count.number : 0;
        return Theme.num(n) + Theme.say(" res possessae", " installed");
    }

    Discover.ResourcesProxyModel {
        id: owned
        stateFilter: Discover.AbstractResource.Installed
        allBackends: true
        sortRole: Discover.ResourcesProxyModel.NameRole
        sortOrder: Qt.AscendingOrder
    }

    ColumnLayout {
        anchors { fill: parent; leftMargin: 34; rightMargin: 34; topMargin: 20 }
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Niche {
                Layout.preferredWidth: 340
                Layout.preferredHeight: 38
                TextInput {
                    id: filter
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.serif
                    font.pixelSize: 17
                    color: Theme.ink
                    clip: true
                    onTextEdited: owned.search = text
                }
                Gloss {
                    visible: filter.text === "" && !filter.activeFocus
                    anchors { left: parent.left; leftMargin: 13; verticalCenter: parent.verticalCenter }
                    text: Theme.say("Quaere in possessis…", "Filter what you own…")
                    size: 16
                }
            }
            Item { Layout.fillWidth: true }
            Lapis {
                visible: Discover.ResourcesModel.updatesCount > 0
                porphyry: true
                text: Theme.say("TRIBVTVM ADVENIT", "UPDATES WAITING") + " · " + Theme.num(Discover.ResourcesModel.updatesCount)
                size: 11
                onClicked: page.forum.openTop("tributum")
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors { fill: parent; rightMargin: 14 }
                clip: true
                model: owned
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 600
                delegate: Merx {
                    forum: page.forum
                }
                footer: Item { width: 1; height: 24 }
            }
            Rail {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom; bottomMargin: 20 }
                flickable: list
            }
            Carved {
                anchors.centerIn: parent
                visible: list.count === 0
                text: owned.busy ? Theme.say("EXSPECTA…", "ONE MOMENT…") : Theme.say("NIHIL", "NOTHING")
                size: 22
                spacing: 0.22
                tone: "faint"
            }
        }
    }
}
