import QtQuick

// The edges that make stone read as stone. Lay it over a Marble or Porphyry.
// raised: a dressed slab, lit at top-left. sunk: a niche cut into the face.
Item {
    id: root
    property bool sunk: false
    property real depth: 1.0
    anchors.fill: parent

    // Raised slab
    Rectangle { visible: !root.sunk; anchors { left: parent.left; right: parent.right; top: parent.top } height: 2; color: Qt.rgba(1, 1, 1, 0.8 * root.depth) }
    Rectangle { visible: !root.sunk; anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 2; color: Qt.rgba(1, 1, 1, 0.8 * root.depth) }
    Rectangle { visible: !root.sunk; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 3; color: Qt.rgba(0.31, 0.27, 0.24, 0.3 * root.depth) }
    Rectangle { visible: !root.sunk; anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 3; color: Qt.rgba(0.31, 0.27, 0.24, 0.3 * root.depth) }

    // Sunk niche: shadow falls from the top-left lip, the far edges catch light.
    Rectangle {
        visible: root.sunk
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Math.min(8, parent.height / 2)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0.22, 0.18, 0.14, 0.5 * root.depth) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    Rectangle {
        visible: root.sunk
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: Math.min(8, parent.width / 2)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(0.22, 0.18, 0.14, 0.42 * root.depth) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    Rectangle { visible: root.sunk; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 2; color: Qt.rgba(1, 1, 1, 0.7 * root.depth) }
    Rectangle { visible: root.sunk; anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 2; color: Qt.rgba(1, 1, 1, 0.7 * root.depth) }
}
