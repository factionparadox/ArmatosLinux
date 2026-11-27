import QtQuick

// Imperial porphyry, the purple stone kept for emperors.
Rectangle {
    color: Theme.porphyryBase
    clip: true

    Image {
        anchors.fill: parent
        source: Theme.asset("porphyry.jpg")
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
    }
}
