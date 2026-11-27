import QtQuick

// A page of the Forum. Only the page on top of the stack is shown; the ones
// beneath keep their place for when you come back.
Item {
    id: page
    property var forum
    property string title
    property string gloss
    property bool isSearch: false

    anchors.fill: parent
    visible: !!forum && forum.topPage === page
}
