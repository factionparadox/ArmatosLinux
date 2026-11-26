import QtQuick

// A piece of Carrara: the book-matched marmor tile.
Rectangle {
    color: Theme.marbleBase
    clip: true

    Image {
        anchors.fill: parent
        source: Theme.asset("marmor.jpg")
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
    }
}
