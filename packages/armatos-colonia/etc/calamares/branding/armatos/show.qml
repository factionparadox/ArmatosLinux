/* colonia: the paintings shown while the colony is built. */
import QtQuick
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 9000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    component Painting: Slide {
        id: slide
        property string image
        property string title
        property string body

        Rectangle { anchors.fill: parent; color: "#16110F" }
        Image {
            anchors.fill: parent
            source: slide.image
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }
        // A marble tablet along the foot, with the inscription.
        Rectangle {
            id: tablet
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 26 }
            height: words.implicitHeight + 36
            color: "#E9E5DF"
            Image {
                anchors.fill: parent
                source: "marmor.jpg"
                fillMode: Image.Tile
                horizontalAlignment: Image.AlignLeft
                verticalAlignment: Image.AlignTop
            }
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 6; color: "#8A6518" }
            Column {
                id: words
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18; topMargin: 22 }
                spacing: 6
                Text {
                    width: parent.width
                    text: slide.title
                    font.family: "Cinzel"
                    font.weight: Font.Black
                    font.pixelSize: 20
                    font.letterSpacing: 3
                    color: "#7A0000"
                    style: Text.Raised
                    styleColor: Qt.rgba(1, 1, 1, 0.85)
                }
                Text {
                    width: parent.width
                    text: slide.body
                    wrapMode: Text.WordWrap
                    font.family: "EB Garamond"
                    font.pixelSize: 18
                    color: "#3A2F29"
                }
            }
        }
    }

    Painting {
        image: "slide-cursus.jpg"
        title: "I · CVRSVS PVBLICVS"
        body: "One order brings in the tribute: cursus updates the apt packages, the Flatpaks and Discord together. Type  cursus  and nothing more."
    }
    Painting {
        image: "slide-damnatio.jpg"
        title: "II · DAMNATIO MEMORIAE"
        body: "Before every update the system is carved into a Btrfs snapshot. If an update goes badly,  damnatio  restores an earlier memory and the bad one is struck from the record."
    }
    Painting {
        image: "slide-porta.jpg"
        title: "III · PORTA"
        body: "The colony is walled with LUKS2: one watchword at boot opens the gates and takes you straight to the desktop. The porta (lock screen) opens to your fingerprint as well."
    }
    Painting {
        image: "slide-titulus.jpg"
        title: "IV · TITVLVS"
        body: "MangoWC lays windows out in scrolling columns across workspaces I to IX. Super+Tab opens the Colosseum; Super+Space asks what you command."
    }
    Painting {
        image: "slide-lingua.jpg"
        title: "V · LINGVA LATINA"
        body: "The empire speaks Latin, with English a click away. Battery, sound and light are read in Roman numerals, or Arabic if you prefer: ROMANI · ARABICI."
    }

    function onActivate() { presentation.currentSlide = 0; }
    function onLeave() { }
}
