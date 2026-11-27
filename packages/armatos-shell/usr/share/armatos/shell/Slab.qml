import QtQuick
import QtQuick.Effects

// A dressed tablet that stands off the wall: marble or porphyry, with a
// cast shadow and bevelled edges. Children go on its face.
Item {
    id: root
    property bool porphyry: false
    property bool shadow: true
    property bool moulding: false            // gilded strip along the top
    property alias seed: marble.seed         // which part of the slab it is cut from
    default property alias content: face.data

    RectangularShadow {
        visible: root.shadow
        anchors.fill: stone
        offset.y: 8
        blur: 18
        spread: 0
        color: Qt.rgba(0, 0, 0, 0.5)
    }

    Item {
        id: stone
        anchors.fill: parent

        Marble { id: marble; anchors.fill: parent; visible: !root.porphyry }
        Porphyry { anchors.fill: parent; visible: root.porphyry }
        Moulding { visible: root.moulding; anchors { left: parent.left; right: parent.right; top: parent.top } }
        Item { id: face; anchors.fill: parent; anchors.topMargin: root.moulding ? Theme.mouldingHeight : 0 }
        Bevel { depth: root.porphyry ? 0.45 : 1 }
    }
}
