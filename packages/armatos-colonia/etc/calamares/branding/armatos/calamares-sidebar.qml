/* colonia: the steps of founding a colony, carved down a porphyry column. */
import io.calamares.ui 1.0
import io.calamares.core 1.0

import QtQuick
import QtQuick.Layouts

Item {
    id: sideBar
    anchors.fill: parent

    // Calamares names its steps in English; the column carries them in Latin
    // with the English underneath.
    readonly property var latin: ({
        "Welcome": "SALVE", "Location": "LOCVS", "Keyboard": "CLAVES",
        "Partitions": "AGER", "Users": "CIVIS", "Summary": "SVMMA",
        "Install": "OPVS", "Finish": "FINIS"
    })

    function roman(n) {
        const t = [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
        let s = "";
        for (const [v, r] of t)
            while (n >= v) { s += r; n -= v; }
        return s;
    }

    Rectangle { anchors.fill: parent; color: "#5E0E18" }
    Image {
        anchors.fill: parent
        source: "porphyry.jpg"
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
    }
    // Gilt edge where the column meets the marble.
    Rectangle { anchors { top: parent.top; bottom: parent.bottom; right: parent.right } width: 2; color: "#C9A24A" }
    Rectangle { anchors { top: parent.top; bottom: parent.bottom; right: parent.right; rightMargin: 3 } width: 1; color: "#3A2A08" }

    ColumnLayout {
        anchors { fill: parent; topMargin: 22; bottomMargin: 18 }
        spacing: 0

        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            source: "file:/" + Branding.imagePath(Branding.ProductLogo)
            sourceSize.width: 192
            sourceSize.height: 192
            fillMode: Image.PreserveAspectFit
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            text: "COLONIA"
            font.family: "Cinzel"
            font.weight: Font.Black
            font.pixelSize: 20
            font.letterSpacing: 4
            color: "#EAC55E"
            style: Text.Raised
            styleColor: "#2A0006"
        }
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            Layout.bottomMargin: 16
            width: 120; height: 1
            color: "#C9A24A"
        }

        Repeater {
            model: ViewManager

            Item {
                required property int index
                required property string display
                readonly property bool current: index === ViewManager.currentStepIndex
                readonly property bool past: index < ViewManager.currentStepIndex
                Layout.fillWidth: true
                Layout.preferredHeight: 52

                // The current step is a marble plaque set into the column.
                Rectangle {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 12; topMargin: 3; bottomMargin: 3 }
                    visible: parent.current
                    color: "#E9E5DF"
                    Image {
                        anchors.fill: parent
                        source: "marmor.jpg"
                        fillMode: Image.Tile
                        horizontalAlignment: Image.AlignLeft
                        verticalAlignment: Image.AlignTop
                    }
                    Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 2; color: Qt.rgba(1, 1, 1, 0.8) }
                    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 2; color: Qt.rgba(0.3, 0.25, 0.2, 0.35) }
                }

                Text {
                    id: numeral
                    anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
                    width: 40
                    text: sideBar.roman(parent.index + 1) + "."
                    font.family: "Cinzel"
                    font.weight: Font.Black
                    font.pixelSize: 14
                    color: parent.current ? "#7A0000" : (parent.past ? "#C9A24A" : "#B89A60")
                }
                Column {
                    anchors { left: numeral.right; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    spacing: 0
                    Text {
                        width: parent.width
                        text: sideBar.latin[parent.parent.display] || parent.parent.display.toUpperCase()
                        font.family: "Cinzel"
                        font.weight: Font.Black
                        font.pixelSize: 14
                        font.letterSpacing: 1.5
                        color: parent.parent.current ? "#3A2F29" : (parent.parent.past ? "#EAC55E" : "#D8BE84")
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: sideBar.latin[parent.parent.display] !== undefined
                        text: parent.parent.display
                        font.family: "EB Garamond"
                        font.italic: true
                        font.pixelSize: 14
                        color: parent.parent.current ? "#5F5650" : "#C9B48A"
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: "ARMATOS\nMMDCCLXXIX"
            lineHeight: 1.2
            font.family: "Cinzel"
            font.weight: Font.Bold
            font.pixelSize: 11
            font.letterSpacing: 2
            color: "#C9A24A"
        }
    }
}
