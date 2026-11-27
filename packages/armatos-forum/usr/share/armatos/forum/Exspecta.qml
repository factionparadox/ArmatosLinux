import QtQuick
import QtQuick.Layouts

// Waiting for the engine to find what was asked for.
Pagina {
    title: Theme.say("EXSPECTA", "PLEASE WAIT")

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10
        Carved {
            id: word
            Layout.alignment: Qt.AlignHCenter
            text: Theme.say("EXSPECTA…", "ONE MOMENT…")
            size: 28
            spacing: 0.3
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.35; to: 1; duration: 900; easing.type: Easing.InOutSine }
            }
        }
        Gloss {
            Layout.alignment: Qt.AlignHCenter
            text: Theme.say("Mercatores merces suas proferunt.", "The merchants are setting out their goods.")
            size: 18
        }
    }
}
