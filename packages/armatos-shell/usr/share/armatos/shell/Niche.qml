import QtQuick

// A recess cut into the marble, for workspaces, the tray and readings.
Marble {
    default property alias content: holder.data
    Item { id: holder; anchors.fill: parent }
    Bevel { sunk: true }
}
