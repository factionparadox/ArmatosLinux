import QtQuick

// Letters cut into stone: a dark lip above, a lit edge below.
// Gilt letters stand proud instead: lit above, shadowed below.
Item {
    id: root

    property string text
    property string family: Theme.caps
    property int size: 14
    property int weight: Font.Black
    property bool italic: false
    property real spacing: 0                 // letter spacing, in em
    property string tone: "ink"              // ink | faint | red | gilt | pale
    property int elide: Text.ElideNone
    property int horizontalAlignment: Text.AlignLeft
    property int wrapMode: Text.NoWrap
    property int maximumLineCount: 1

    readonly property color face: tone === "red" ? Theme.red
                                : tone === "gilt" ? Theme.gilt
                                : tone === "faint" ? Theme.faint
                                : tone === "pale" ? "#EDE6DC"
                                : Theme.ink
    readonly property color above: tone === "gilt" ? Qt.rgba(1, 0.93, 0.75, 0.35)
                                 : tone === "pale" ? Qt.rgba(0, 0, 0, 0.55)
                                 : Qt.rgba(0, 0, 0, tone === "faint" ? 0.14 : 0.28)
    readonly property color below: tone === "gilt" ? Qt.rgba(0, 0, 0, 0.7)
                                 : tone === "pale" ? Qt.rgba(0, 0, 0, 0.35)
                                 : Qt.rgba(1, 1, 1, 0.9)

    implicitWidth: letters.implicitWidth
    implicitHeight: letters.implicitHeight

    component Cut: Text {
        width: root.width
        text: root.text
        textFormat: Text.PlainText
        font.family: root.family
        font.pixelSize: root.size
        font.weight: root.weight
        font.italic: root.italic
        font.letterSpacing: root.spacing * root.size
        elide: root.elide
        wrapMode: root.wrapMode
        maximumLineCount: root.maximumLineCount
        horizontalAlignment: root.horizontalAlignment
    }

    Cut { y: -1; color: root.above }
    Cut { y: 1; color: root.below }
    Cut { id: letters; color: root.face }
}
