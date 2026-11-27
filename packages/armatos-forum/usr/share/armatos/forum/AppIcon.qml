import QtQuick
import org.kde.kirigami.primitives as Primitives

// A program's icon. Discover hands over a theme name, a file or a QIcon;
// Kirigami's Icon understands all three. Where there is none (most system
// packages), the name's first letter is cut instead, like a monogram.
Item {
    id: root
    property var resourceIcon
    property string name

    Primitives.Icon {
        id: icon
        anchors.fill: parent
        // Generic package icons say nothing; the monogram says more.
        source: root.resourceIcon === undefined || root.resourceIcon === null
                || ["applications-other", "package-x-generic", "application-x-executable"].indexOf(String(root.resourceIcon)) >= 0
                ? "" : root.resourceIcon
        fallback: ""
        placeholder: ""
        smooth: true
        visible: valid && status !== Primitives.Icon.Error
    }

    Carved {
        anchors.centerIn: parent
        visible: !icon.visible
        text: root.name !== "" ? root.name.charAt(0).toUpperCase() : "·"
        size: Math.round(root.height * 0.62)
        tone: "faint"
    }
}
