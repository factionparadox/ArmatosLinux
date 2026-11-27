import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover

// The porphyry column: the Forum's name, its five halls, the stalls
// (categories) and, at the foot, the work in hand.
Porphyry {
    id: column
    property var forum

    component Hall: Item {
        id: hall
        property string key
        property string latin
        property string english
        property string mark: ""
        property var forum
        readonly property bool here: !!forum && forum.current === key

        Layout.fillWidth: true
        implicitHeight: 48

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, hall.here ? 0.28 : hallArea.containsMouse ? 0.14 : 0)
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Rectangle {
            visible: hall.here
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 4
            color: Theme.gilt
        }
        ColumnLayout {
            anchors { left: parent.left; right: markNiche.left; verticalCenter: parent.verticalCenter; leftMargin: 24; rightMargin: 8 }
            spacing: 0
            Carved {
                text: hall.latin
                size: 15
                spacing: 0.2
                tone: "gilt"
            }
            Carved {
                visible: Theme.lingua === "en"
                text: hall.english
                family: Theme.serif
                size: 13
                weight: Font.Normal
                italic: true
                tone: "pale"
            }
        }
        Niche {
            id: markNiche
            visible: hall.mark !== ""
            anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            width: Math.max(30, markText.implicitWidth + 14)
            height: 26
            Carved {
                id: markText
                anchors.centerIn: parent
                text: hall.mark
                size: 12
                tone: "red"
            }
        }
        MouseArea {
            id: hallArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hall.forum.openTop(hall.key)
        }
    }

    Bevel { depth: 0.45 }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // The name over the door.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 128

            Image {
                id: eagle
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 16 }
                source: Theme.asset("eagle@2x.png")
                width: 52
                height: 52
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
            Carved {
                anchors { horizontalCenter: parent.horizontalCenter; top: eagle.bottom; topMargin: 6 }
                text: "FORVM"
                size: 26
                spacing: 0.32
                tone: "gilt"
            }
            Carved {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 10 }
                text: Theme.say("mercatus imperii", "the empire's market")
                family: Theme.serif
                size: 14
                weight: Font.Normal
                italic: true
                tone: "pale"
            }
        }

        Moulding { Layout.fillWidth: true }

        Item { Layout.preferredHeight: 10 }

        Hall { forum: column.forum; key: "tabernae"; latin: "TABERNAE"; english: "the stalls" }
        Hall { forum: column.forum; key: "quaere"; latin: "QVAERE"; english: "search" }
        Hall { forum: column.forum; key: "possessa"; latin: "POSSESSA"; english: "installed" }
        Hall {
            forum: column.forum
            key: "tributum"
            latin: "TRIBVTVM"
            english: "updates"
            mark: Discover.ResourcesModel.fetchingUpdatesProgress < 100 ? "…"
                : Discover.ResourcesModel.updatesCount > 0 ? Theme.num(Discover.ResourcesModel.updatesCount) : ""
        }
        Hall { forum: column.forum; key: "fontes"; latin: "FONTES"; english: "sources" }

        Item { Layout.preferredHeight: 12 }

        Carved {
            Layout.leftMargin: 24
            text: Theme.say("TABERNAE", "STALLS")
            size: 11
            spacing: 0.3
            tone: "pale"
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.topMargin: 6
            Layout.preferredHeight: 1
            color: Qt.rgba(0.92, 0.77, 0.37, 0.35)
        }

        // The stalls, from Discover's categories.
        Flickable {
            id: stallsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 4
            clip: true
            contentHeight: stallsColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: stallsColumn
                width: stallsView.width

                Repeater {
                    model: Discover.CategoryModel.rootCategories
                    delegate: Item {
                        id: stall
                        required property var modelData
                        readonly property var category: Discover.CategoryModel.get(modelData)
                        readonly property bool shown: !!category && category.visible && !Theme.hiddenStall(category.name)
                        width: stallsColumn.width
                        height: shown ? 32 : 0
                        visible: shown

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, stallArea.containsMouse ? 0.14 : 0)
                        }
                        Carved {
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 30; rightMargin: 16 }
                            text: stall.category ? (Theme.lingua === "en" ? stall.category.name.toUpperCase() : Theme.stall(stall.category.name)) : ""
                            size: 12
                            spacing: 0.16
                            tone: "gilt"
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: stallArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: column.forum.openCategory(stall.modelData)
                        }
                    }
                }
            }
        }

        // Opera: the work in hand.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Discover.TransactionModel.count > 0 ? 86 : 0
            visible: Discover.TransactionModel.count > 0
            clip: true

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 24; rightMargin: 24 }
                height: 1
                color: Qt.rgba(0.92, 0.77, 0.37, 0.35)
            }
            ColumnLayout {
                anchors { fill: parent; leftMargin: 24; rightMargin: 24; topMargin: 12; bottomMargin: 14 }
                spacing: 6
                Carved {
                    text: Theme.say("OPERA", "IN HAND") + " · " + Theme.num(Discover.TransactionModel.count)
                    size: 11
                    spacing: 0.3
                    tone: "pale"
                }
                Carved {
                    Layout.fillWidth: true
                    text: Discover.TransactionModel.mainTransactionText
                    family: Theme.serif
                    size: 14
                    weight: Font.Medium
                    italic: true
                    tone: "gilt"
                    elide: Text.ElideRight
                }
                Niche {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 2 }
                        width: Math.max(0, (parent.width - 4) * Math.min(1, Discover.TransactionModel.progress / 100))
                        color: Theme.giltDeep
                        Behavior on width { NumberAnimation { duration: 250 } }
                    }
                }
            }
        }

        // About the Forum.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Carved {
                anchors.centerIn: parent
                text: Theme.say("DE FORO", "ABOUT FORUM")
                size: 10
                spacing: 0.3
                tone: aboutArea.containsMouse ? "gilt" : "pale"
            }
            MouseArea {
                id: aboutArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: column.forum.openTop("deforo")
            }
        }
    }
}
