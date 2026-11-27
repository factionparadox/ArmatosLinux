import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover

// One piece of merchandise in a list: icon in a niche, name, a line about
// it, where it comes from, and what can be done with it.
Item {
    id: root

    required property var application
    property var forum
    property bool showAction: true
    property bool veto: false
    // Discover and its backends are the Forum's own engine: kept out of
    // ordinary lists, shown only where Fontes offers them as add-ons.
    property bool showEngine: false
    readonly property bool engine: !!application && application.appstreamId.indexOf("org.kde.discover") === 0
    readonly property bool hidden: veto || !application || (engine && !showEngine)

    width: ListView.view ? ListView.view.width : implicitWidth
    implicitHeight: hidden ? 0 : 96
    height: implicitHeight
    visible: !hidden

    Slab {
        anchors { fill: parent; bottomMargin: 10 }
        shadow: false

        Rectangle {
            anchors.fill: parent
            color: "white"
            opacity: area.containsMouse ? 0.16 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.forum.push("Res", { application: root.application })
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 16 }
            spacing: 16

            Niche {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                AppIcon {
                    anchors.centerIn: parent
                    width: 46
                    height: 46
                    resourceIcon: root.application ? root.application.icon : ""
                    name: root.application ? root.application.name : ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Carved {
                        Layout.fillWidth: true
                        text: root.application ? root.application.name : ""
                        size: 17
                        weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    // In a list only foreign goods are marked; the rest are
                    // the empire's own (their origin isn't known until asked).
                    Badge {
                        resource: root.application
                        visible: foreign
                    }
                }
                Gloss {
                    Layout.fillWidth: true
                    text: root.application ? root.application.comment : ""
                    size: 16
                    tone: "ink"
                    elide: Text.ElideRight
                }
                Carved {
                    visible: !!root.application && root.application.isInstalled
                    text: root.application && root.application.canUpgrade
                          ? Theme.say("POSSESSVM · TRIBVTVM ADVENIT", "INSTALLED · UPDATE WAITING")
                          : Theme.say("POSSESSVM", "INSTALLED")
                    size: 10
                    spacing: 0.2
                    tone: root.application && root.application.canUpgrade ? "red" : "faint"
                }
            }

            Actio {
                visible: root.showAction
                compact: true
                application: root.application
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
