import QtQuick
import QtQuick.Layouts

// A section heading in red capitals over a thin cut groove.
ColumnLayout {
    property alias text: heading.text
    spacing: 5

    Carved {
        id: heading
        size: 12
        spacing: 0.26
        tone: "red"
    }
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 3
        Bevel { sunk: true }
    }
}
