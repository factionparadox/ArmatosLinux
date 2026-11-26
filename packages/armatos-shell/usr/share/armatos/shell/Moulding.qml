import QtQuick

// Gilded bead-and-reel, the moulding under the Titulus and atop each tablet.
Rectangle {
    implicitHeight: Theme.mouldingHeight
    color: "#5C430E"
    clip: true

    Image {
        anchors.fill: parent
        source: Theme.asset("beadreel.png")
        fillMode: Image.TileHorizontally
        horizontalAlignment: Image.AlignLeft
    }
}
