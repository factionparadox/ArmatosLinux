import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover
import org.kde.discover.app as DiscoverApp

// The Forum's front: SELECTA (goods the empire recommends) and the stalls.
Pagina {
    id: page
    title: "TABERNAE"
    gloss: Theme.say("Merces ex toto imperio.", "Goods from all over the empire.")

    DiscoverApp.FeaturedModel {
        id: selecta
    }

    readonly property var notice: Discover.ResourcesModel.inlineMessage ? Discover.ResourcesModel.inlineMessage : app.homePageMessage
    // Why the stalls might be bare (PackageKit down, no metadata). Asked
    // again now and then, since the engine doesn't announce a change.
    property var dysfunction: null
    function recheck() {
        dysfunction = selecta.currentApplicationBackend ? selecta.currentApplicationBackend.explainDysfunction() : null;
    }
    Timer {
        interval: 4000
        repeat: true
        running: page.visible && selecta.count === 0
        triggeredOnStart: true
        onTriggered: page.recheck()
    }

    Flickable {
        id: view
        anchors { fill: parent; rightMargin: 14 }
        contentHeight: body.implicitHeight + 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: body
            x: 34
            y: 26
            width: view.width - 60
            spacing: 18

            // A notice from the engine (PackageKit is down, for example).
            Slab {
                Layout.fillWidth: true
                Layout.preferredHeight: noticeText.implicitHeight + 28
                visible: !!page.notice && (page.notice.message || "") !== ""
                porphyry: true
                shadow: false
                Carved {
                    id: noticeText
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 18 }
                    text: page.notice ? Theme.plain(page.notice.message) : ""
                    family: Theme.serif
                    size: 16
                    weight: Font.Medium
                    tone: "gilt"
                    wrapMode: Text.Wrap
                    maximumLineCount: 5
                }
            }

            // SELECTA
            RowLayout {
                Layout.fillWidth: true
                visible: selecta.count > 0 || selecta.isFetching
                spacing: 14
                Carved { text: "SELECTA"; size: 18; spacing: 0.3; tone: "red" }
                Gloss { text: Theme.say("quae imperium commendat", "what the empire recommends") }
                Item { Layout.fillWidth: true }
                Gloss { visible: selecta.isFetching; text: Theme.say("exspecta…", "loading…") }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 16
                visible: selecta.count > 0

                Repeater {
                    model: selecta
                    delegate: Item {
                        id: tile
                        required property var application
                        readonly property bool shown: !!application
                        width: (body.width - 16 * 2) / 3
                        height: shown ? 128 : 0
                        visible: shown

                        Slab {
                            anchors.fill: parent
                            moulding: true

                            Rectangle {
                                anchors.fill: parent
                                color: "white"
                                opacity: tileArea.containsMouse ? 0.16 : 0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }
                            MouseArea {
                                id: tileArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.forum.push("Res", { application: tile.application })
                            }
                            RowLayout {
                                anchors { fill: parent; margins: 16 }
                                spacing: 14
                                Niche {
                                    Layout.preferredWidth: 72
                                    Layout.preferredHeight: 72
                                    Layout.alignment: Qt.AlignTop
                                    AppIcon {
                                        anchors.centerIn: parent
                                        width: 52
                                        height: 52
                                        resourceIcon: tile.application ? tile.application.icon : ""
                                        name: tile.application ? tile.application.name : ""
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4
                                    Carved {
                                        Layout.fillWidth: true
                                        text: tile.application ? tile.application.name : ""
                                        size: 16
                                        weight: Font.Bold
                                        elide: Text.ElideRight
                                    }
                                    Gloss {
                                        Layout.fillWidth: true
                                        text: tile.application ? tile.application.comment : ""
                                        tone: "ink"
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                    Item { Layout.fillHeight: true }
                                    Carved {
                                        visible: !!tile.application && tile.application.isInstalled
                                        text: Theme.say("POSSESSVM", "INSTALLED")
                                        size: 10
                                        spacing: 0.2
                                        tone: "faint"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Nothing to sell: say why, and offer the engine's own remedy.
            Slab {
                Layout.fillWidth: true
                Layout.preferredHeight: helpColumn.implicitHeight + 36
                visible: !selecta.isFetching && selecta.count === 0 && !!page.dysfunction
                shadow: false
                ColumnLayout {
                    id: helpColumn
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 20 }
                    spacing: 10
                    Carved {
                        Layout.fillWidth: true
                        text: page.dysfunction ? Theme.plain(page.dysfunction.message) : ""
                        family: Theme.serif
                        size: 17
                        weight: Font.Medium
                        wrapMode: Text.Wrap
                        maximumLineCount: 6
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 10
                        Repeater {
                            model: page.dysfunction ? page.dysfunction.actions : []
                            delegate: Lapis {
                                required property var modelData
                                text: (modelData.text || "").replace(/&/g, "").toUpperCase()
                                onClicked: modelData.trigger()
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 6 }

            // The stalls, carved as tablets.
            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Carved { text: "TABERNAE"; size: 18; spacing: 0.3; tone: "red" }
                Gloss { text: Theme.say("quaere per genera", "browse by kind") }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 16

                Repeater {
                    id: stalls
                    model: Discover.CategoryModel.rootCategories
                    delegate: Item {
                        id: stall
                        required property var modelData
                        required property int index
                        readonly property var category: Discover.CategoryModel.get(modelData)
                        readonly property bool shown: !!category && category.visible && !Theme.hiddenStall(category.name)
                        width: (body.width - 16 * 3) / 4
                        height: shown ? 96 : 0
                        visible: shown

                        Slab {
                            anchors.fill: parent
                            shadow: false

                            Rectangle {
                                anchors.fill: parent
                                color: "white"
                                opacity: stallArea.containsMouse ? 0.18 : 0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }
                            Carved {
                                anchors { top: parent.top; right: parent.right; margins: 10 }
                                text: Theme.roman(stall.index + 1)
                                size: 11
                                tone: "faint"
                            }
                            ColumnLayout {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
                                spacing: 2
                                Carved {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: stall.category ? Theme.stall(stall.category.name) : ""
                                    size: 17
                                    spacing: 0.14
                                    elide: Text.ElideRight
                                }
                                Gloss {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: stall.category ? stall.category.name : ""
                                    size: 14
                                    elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: stallArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.forum.openCategory(stall.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    Rail {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: 8 }
        flickable: view
    }
}
