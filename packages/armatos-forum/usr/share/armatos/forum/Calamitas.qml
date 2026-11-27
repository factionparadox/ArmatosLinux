import QtQuick
import QtQuick.Layouts

// Something went wrong in a way the engine wants a whole page for.
Pagina {
    id: page
    property string message
    property string explanation
    property string buttonText
    property string buttonUrl

    title: Theme.say("CALAMITAS", "SOMETHING WENT WRONG")

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(640, parent.width - 80)
        spacing: 16

        Carved {
            Layout.alignment: Qt.AlignHCenter
            text: Theme.say("IVSSVM DEFECIT", "THE ORDER FAILED")
            size: 22
            spacing: 0.22
            tone: "red"
        }
        Carved {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: page.message
            family: Theme.serif
            size: 20
            weight: Font.Medium
            wrapMode: Text.Wrap
            maximumLineCount: 4
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: page.explanation
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            font.family: Theme.serif
            font.pixelSize: 17
            color: Theme.faint
            linkColor: Theme.red
            style: Text.Sunken
            styleColor: Qt.rgba(1, 1, 1, 0.8)
            onLinkActivated: link => Qt.openUrlExternally(link)
        }
        Lapis {
            Layout.alignment: Qt.AlignHCenter
            visible: page.buttonText !== "" && page.buttonUrl !== ""
            text: page.buttonText.toUpperCase()
            onClicked: Qt.openUrlExternally(page.buttonUrl)
        }
    }
}
