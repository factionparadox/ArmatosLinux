import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover

// One piece of software, displayed on its own tablet: what it is, where it
// comes from, pictures of it, and the stone to press.
Pagina {
    id: page

    property var application
    readonly property bool technical: !!application && (application.type === Discover.AbstractResource.ApplicationSupport
                                                      || application.type === Discover.AbstractResource.System)

    title: application ? application.name.toUpperCase() : ""
    gloss: application ? application.comment : ""

    // The same program from other sources (a .deb and a Flatpak, say).
    Discover.ResourcesProxyModel {
        id: sources
        resourcesUrl: page.application ? page.application.url : ""
        allBackends: true
    }

    Discover.ScreenshotsModel {
        id: pictures
        application: page.application
    }

    component Fact: Niche {
        property string label
        property string value
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        visible: value !== ""
        ColumnLayout {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 14 }
            spacing: 2
            Carved { text: label; size: 10; spacing: 0.25; tone: "faint" }
            Carved {
                Layout.fillWidth: true
                text: value
                family: Theme.serif
                size: 17
                weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    component Link: Lapis {
        property url target
        visible: target.toString() !== ""
        size: 11
        implicitHeight: 32
        onClicked: Qt.openUrlExternally(target)
    }

    Flickable {
        id: view
        anchors { fill: parent; rightMargin: 14 }
        contentHeight: body.implicitHeight + 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: body
            x: Math.max(34, (view.width - 1040) / 2)
            y: 26
            width: Math.min(1040, view.width - 68)
            spacing: 20

            // The tablet: icon, name, maker, and the stones to press.
            Slab {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(196, heroText.implicitHeight + Theme.mouldingHeight + 48)
                moulding: true

                RowLayout {
                    anchors { fill: parent; margins: 24 }
                    spacing: 24

                    Niche {
                        Layout.preferredWidth: 128
                        Layout.preferredHeight: 128
                        Layout.alignment: Qt.AlignTop
                        AppIcon {
                            anchors.centerIn: parent
                            width: 96
                            height: 96
                            resourceIcon: page.application ? page.application.icon : ""
                            name: page.application ? page.application.name : ""
                        }
                    }

                    ColumnLayout {
                        id: heroText
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 6

                        Carved {
                            Layout.fillWidth: true
                            text: page.application ? page.application.name : ""
                            size: 30
                            spacing: 0.06
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                        Gloss {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: page.application ? (page.application.author !== "" ? Theme.say("a ", "by ") + page.application.author : "") : ""
                            size: 17
                        }
                        Carved {
                            Layout.fillWidth: true
                            text: page.application ? page.application.comment : ""
                            family: Theme.serif
                            size: 19
                            weight: Font.Medium
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                        }
                        RowLayout {
                            spacing: 10
                            Badge { resource: page.application }
                            Carved {
                                visible: !!page.application && page.application.verifiedMessage !== ""
                                text: Theme.say("PROBATVS", "VERIFIED")
                                size: 10
                                spacing: 0.2
                                tone: "red"
                            }
                        }
                        Item { Layout.preferredHeight: 6 }
                        RowLayout {
                            spacing: 12
                            Actio {
                                application: page.application
                            }
                            Lapis {
                                visible: !!page.application && page.application.isInstalled && page.application.canExecute
                                porphyry: true
                                text: Theme.say("INCIPE", "LAUNCH")
                                onClicked: page.application.invokeApplication()
                            }
                        }
                    }
                }
            }

            // Other sources for the same program: the empire's own first.
            RowLayout {
                Layout.fillWidth: true
                visible: sources.count && sources.count.valid && sources.count.number > 1
                spacing: 10
                Carved { text: Theme.say("EX ALIIS FONTIBVS", "FROM OTHER SOURCES"); size: 11; spacing: 0.25; tone: "faint" }
                Repeater {
                    model: sources
                    delegate: Lapis {
                        required property var application
                        required property string displayOrigin
                        porphyry: application === page.application
                        text: (Theme.isForeign(application) ? "PEREGRINA · " : "") + displayOrigin.toUpperCase()
                        size: 10
                        implicitHeight: 30
                        onClicked: page.application = application
                    }
                }
            }

            // The facts, each in its niche.
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Fact {
                    label: Theme.say("VERSIO", "VERSION")
                    value: page.application ? page.application.versionString : ""
                }
                Fact {
                    label: Theme.say("MAGNITVDO", "SIZE")
                    value: page.application ? page.application.sizeDescription : ""
                }
                Fact {
                    label: Theme.say("ORIGO", "SOURCE")
                    value: page.application ? page.application.displayOrigin : ""
                }
                Fact {
                    label: Theme.say("LICENTIA", "LICENCE")
                    value: {
                        if (!page.application)
                            return "";
                        const names = [];
                        for (const l of page.application.licenses)
                            names.push(l.name);
                        return names.join(", ");
                    }
                }
                Fact {
                    label: Theme.say("AETAS", "AGE")
                    value: page.application && page.application.contentRatingMinimumAge > 0
                        ? Theme.num(page.application.contentRatingMinimumAge) + "+" : ""
                }
            }

            // Pictures of it, in a row of niches.
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                visible: pictures.count > 0 && !page.technical
                orientation: ListView.Horizontal
                spacing: 16
                clip: true
                model: pictures
                boundsBehavior: Flickable.StopAtBounds
                delegate: Niche {
                    id: shot
                    required property url small_image_url
                    required property url large_image_url
                    height: 250
                    width: Math.max(180, Math.min(440, thumb.implicitWidth > 0 ? 226 * thumb.implicitWidth / Math.max(1, thumb.implicitHeight) + 24 : 400))

                    Image {
                        id: thumb
                        anchors { fill: parent; margins: 12 }
                        source: shot.small_image_url
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        mipmap: true
                    }
                    Gloss {
                        anchors.centerIn: parent
                        visible: thumb.status !== Image.Ready
                        text: thumb.status === Image.Error ? Theme.say("imago deest", "no picture") : Theme.say("exspecta…", "loading…")
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.forum.picture = shot.large_image_url
                    }
                }
            }

            // What its makers say about it.
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: page.application ? page.application.longDescription : ""
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                font.family: Theme.serif
                font.pixelSize: 18
                lineHeight: 1.12
                color: Theme.ink
                linkColor: Theme.red
                style: Text.Sunken
                styleColor: Qt.rgba(1, 1, 1, 0.75)
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            // Where to read more.
            Flow {
                Layout.fillWidth: true
                spacing: 10
                Link { text: Theme.say("DOMVS", "WEBSITE"); target: page.application ? page.application.homepage : "" }
                Link { text: Theme.say("AVXILIVM", "HELP"); target: page.application ? page.application.helpURL : "" }
                Link { text: Theme.say("VITIA NVNTIA", "REPORT A BUG"); target: page.application ? page.application.bugURL : "" }
                Link { text: Theme.say("DONA", "DONATE"); target: page.application ? page.application.donationURL : "" }
                Link { text: Theme.say("ADIVVA", "CONTRIBUTE"); target: page.application ? page.application.contributeURL : "" }
            }

            Gloss {
                Layout.fillWidth: true
                visible: !!page.application && page.application.packageName !== ""
                text: Theme.say("Sarcina: ", "Package: ") + (page.application ? page.application.packageName : "")
                size: 14
            }
        }
    }

    Rail {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: 8 }
        flickable: view
    }
}
