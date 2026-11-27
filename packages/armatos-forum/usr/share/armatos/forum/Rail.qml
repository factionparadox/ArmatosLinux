import QtQuick

// A thin gilt rail that shows how far down a Flickable you are; drag it.
Item {
    id: root
    property Flickable flickable
    readonly property real ratio: flickable && flickable.contentHeight > 0 ? flickable.height / flickable.contentHeight : 1

    width: 8
    visible: ratio < 0.999
    opacity: area.containsMouse || area.pressed || (flickable && flickable.moving) ? 1 : 0.55
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 2
        height: parent.height
        color: Qt.rgba(0.23, 0.18, 0.16, 0.18)
    }

    Rectangle {
        id: thumb
        anchors.horizontalCenter: parent.horizontalCenter
        width: 4
        radius: 0
        height: Math.max(36, root.height * root.ratio)
        y: root.flickable && root.flickable.contentHeight > root.flickable.height
           ? (root.height - height) * (root.flickable.contentY - root.flickable.originY) / (root.flickable.contentHeight - root.flickable.height)
           : 0
        color: Theme.giltDeep
        border.color: Qt.rgba(1, 0.9, 0.6, 0.5)
        border.width: 1
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        function seek(mouseY) {
            const f = root.flickable;
            if (!f || f.contentHeight <= f.height)
                return;
            const t = Math.max(0, Math.min(1, (mouseY - thumb.height / 2) / (root.height - thumb.height)));
            f.contentY = f.originY + t * (f.contentHeight - f.height);
        }
        onPressed: mouse => seek(mouse.y)
        onPositionChanged: mouse => { if (pressed) seek(mouse.y); }
    }
}
