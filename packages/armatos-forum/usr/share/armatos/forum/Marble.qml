import QtQuick

// Marble facing, laid the way a wall is revetted: whole slabs of one photo,
// never mirrored. A small surface is cut from somewhere in a slab (where is
// set by seed, so neighbours differ); a surface bigger than a slab gets
// several, edge to edge with fine joints, every other one turned end for end
// so the veins keep running the same way.
Item {
    id: root

    property real seed: Math.random()

    // One slab in logical pixels (the photo is 1500x1420). A slab may be
    // cut up to 1.6 times larger before a surface needs a second one; long
    // thin pieces (rows, friezes) may run to 2.2, so they stay whole.
    readonly property real slabWidth: 1000
    readonly property real slabHeight: 947
    readonly property real stretch: height < slabHeight * 0.4 ? 2.2 : 1.6
    readonly property int columns: Math.max(1, Math.ceil(width / (slabWidth * stretch) - 0.001))
    readonly property int rows: Math.max(1, Math.ceil(height / (slabHeight * stretch) - 0.001))
    readonly property real cellWidth: width / columns
    readonly property real cellHeight: height / rows
    readonly property real cut: Math.max(1, cellWidth / slabWidth, cellHeight / slabHeight)

    clip: true

    function pick(n, salt) {
        const v = Math.sin(seed * 1000 + n * 12.9898 + salt * 78.233) * 43758.5453;
        return v - Math.floor(v);
    }

    // Behind everything the surface holds: the base colour, then the slabs.
    Rectangle {
        anchors.fill: parent
        color: Theme.marbleBase
    }

    Item {
        anchors.fill: parent

        Repeater {
            model: root.width > 0 && root.height > 0 ? root.columns * root.rows : 0
            delegate: Item {
                id: cell
                required property int index
                readonly property int column: index % root.columns
                readonly property int row: Math.floor(index / root.columns)

                x: column * root.cellWidth
                y: row * root.cellHeight
                width: root.cellWidth
                height: root.cellHeight
                clip: true

                Image {
                    source: Theme.slab
                    width: root.slabWidth * root.cut
                    height: root.slabHeight * root.cut
                    sourceSize.width: 1500
                    sourceSize.height: 1420
                    x: -root.pick(cell.index, 1) * Math.max(0, width - cell.width)
                    y: -root.pick(cell.index, 2) * Math.max(0, height - cell.height)
                    rotation: (cell.column + cell.row) % 2 === 1 ? 180 : 0
                    smooth: true
                    mipmap: true
                }

                // The joint: a hairline of shadow with a lit edge beside it.
                Rectangle {
                    visible: cell.column > 0
                    width: 1
                    height: parent.height
                    color: Qt.rgba(0.23, 0.18, 0.16, 0.22)
                }
                Rectangle {
                    visible: cell.column > 0
                    x: 1
                    width: 1
                    height: parent.height
                    color: Qt.rgba(1, 1, 1, 0.55)
                }
                Rectangle {
                    visible: cell.row > 0
                    width: parent.width
                    height: 1
                    color: Qt.rgba(0.23, 0.18, 0.16, 0.22)
                }
                Rectangle {
                    visible: cell.row > 0
                    y: 1
                    width: parent.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.55)
                }
            }
        }
    }
}
