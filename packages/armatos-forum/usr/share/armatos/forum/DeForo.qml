import QtQuick
import QtQuick.Layouts

// About the Forum, and whose work it stands on.
Pagina {
    id: page
    title: Theme.say("DE FORO", "ABOUT FORUM")
    gloss: Theme.say("Quis hoc forum aedificavit.", "Who built this market.")

    Flickable {
        id: view
        anchors { fill: parent; rightMargin: 14 }
        contentHeight: body.implicitHeight + 80
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: body
            x: Math.max(34, (view.width - 760) / 2)
            y: 40
            width: Math.min(760, view.width - 68)
            spacing: 18

            Image {
                Layout.alignment: Qt.AlignHCenter
                source: Theme.asset("emblem@2x.png")
                Layout.preferredWidth: 150
                Layout.preferredHeight: 150
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
            Carved {
                Layout.alignment: Qt.AlignHCenter
                text: "FORVM ARMATORVM"
                size: 28
                spacing: 0.3
            }
            Gloss {
                Layout.alignment: Qt.AlignHCenter
                text: Theme.say("mercatus imperii", "the empire's market")
                size: 19
            }

            Slab {
                Layout.fillWidth: true
                Layout.preferredHeight: words.implicitHeight + Theme.mouldingHeight + 48
                moulding: true

                ColumnLayout {
                    id: words
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28; topMargin: 22 }
                    spacing: 14

                    component Para: Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        textFormat: Text.StyledText
                        font.family: Theme.serif
                        font.pixelSize: 18
                        color: Theme.ink
                        linkColor: Theme.red
                        style: Text.Sunken
                        styleColor: Qt.rgba(1, 1, 1, 0.8)
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }

                    Para {
                        text: "Forum is the software market of Armatos Linux. Its engine is "
                            + "<a href=\"https://apps.kde.org/discover/\">KDE Discover</a> 6.6, rebuilt "
                            + "without its web view (no QtWebEngine, no Chromium), without the snap "
                            + "backend and without telemetry. Its face, the marble and porphyry you see "
                            + "here, is Armatos's own."
                    }
                    Para {
                        text: "Goods come through PackageKit from the APT archives. Flatpak apps are "
                            + "<i>peregrina</i>, foreign goods: they appear only once a Flatpak remote "
                            + "(Flathub, say) is added under FONTES, and they always carry the porphyry "
                            + "seal. Firmware arrives with the tribute through fwupd."
                    }
                    Para {
                        text: "Discover is free software by the KDE community, under the GNU General "
                            + "Public License. Forum's own pages are part of Armatos."
                    }
                }
            }

            Carved {
                Layout.alignment: Qt.AlignHCenter
                text: "MMDCCLXXIX AB VRBE CONDITA"
                size: 12
                spacing: 0.3
                tone: "faint"
            }
        }
    }

    Rail {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: 8 }
        flickable: view
    }
}
