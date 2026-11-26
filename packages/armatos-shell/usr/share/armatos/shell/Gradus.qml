import QtQuick
import QtQuick.Layouts

// A graduated groove, I to X, with a porphyry fill and a gilt pointer.
// value runs 0..100. Click or drag to set; the wheel nudges by five.
Item {
    id: root
    property real value: 0
    signal moved(real value)

    Layout.fillWidth: true
    implicitHeight: 42

    function setFrom(x) {
        const v = Math.max(0, Math.min(100, (x - groove.x) / groove.width * 100));
        root.moved(Math.round(v));
    }

    Niche {
        id: groove
        x: 8
        width: parent.width - 16
        y: 6
        height: 10
    }
    Porphyry {
        x: groove.x + 2
        y: groove.y + 2
        height: 6
        width: Math.max(0, (groove.width - 4) * Math.min(1, root.value / 100))
    }

    // Graduation marks and numerals
    Repeater {
        model: 11
        Item {
            required property int index
            x: groove.x + groove.width * index / 10 - 1
            y: 20
            Rectangle { width: 2; height: index % 5 === 0 ? 10 : 6; color: "#4A3F38" }
            Rectangle { x: 2; width: 1; height: index % 5 === 0 ? 10 : 6; color: Qt.rgba(1, 1, 1, 0.8) }
            Carved {
                visible: index > 0
                x: -width / 2 + 1
                y: 11
                text: Theme.roman(index)
                size: 9
                weight: Font.Bold
            }
        }
    }

    // The pointer
    Canvas {
        id: pointer
        width: 16; height: 14
        x: groove.x + groove.width * Math.min(1, root.value / 100) - 8
        y: -5
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.beginPath();
            ctx.moveTo(1, 1); ctx.lineTo(15, 1); ctx.lineTo(8, 13); ctx.closePath();
            const g = ctx.createLinearGradient(0, 0, 0, 14);
            g.addColorStop(0, "#F6DE8C");
            g.addColorStop(1, "#8A6518");
            ctx.fillStyle = g;
            ctx.fill();
            ctx.strokeStyle = "#5C430E";
            ctx.lineWidth = 1;
            ctx.stroke();
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFrom(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFrom(mouse.x); }
        onWheel: wheel => root.moved(Math.max(0, Math.min(100, root.value + (wheel.angleDelta.y > 0 ? 5 : -5))))
    }
}
