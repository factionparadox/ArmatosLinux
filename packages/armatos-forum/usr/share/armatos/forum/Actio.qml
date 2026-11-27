import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover

// What can be done with a piece of software: acquire it, cast it out, or
// watch the work in hand. Casting out asks "CERTE?" first.
Item {
    id: root

    property var application
    property bool compact: false
    readonly property bool busy: listener.isActive
    readonly property bool installed: !!application && application.isInstalled
    readonly property bool broken: !application || application.state === Discover.AbstractResource.Broken
    property bool armed: false

    implicitWidth: busy ? (compact ? 200 : 300) : button.implicitWidth
    implicitHeight: compact ? 34 : 40

    Discover.TransactionListener {
        id: listener
        resource: root.application
    }

    Timer {
        id: disarm
        interval: 3500
        onTriggered: root.armed = false
    }

    function act() {
        if (busy || broken)
            return;
        if (installed) {
            if (!armed) {
                armed = true;
                disarm.restart();
                return;
            }
            armed = false;
            Discover.ResourcesModel.removeApplication(application);
        } else {
            Discover.ResourcesModel.installApplication(application);
        }
    }

    Lapis {
        id: button
        anchors.fill: parent
        visible: !root.busy && (!root.installed || root.application.isRemovable)
        enabled: !root.broken
        porphyry: !root.installed || root.armed
        size: root.compact ? 12 : 13
        text: root.broken ? Theme.say("EXSPECTA", "WAIT")
            : !root.installed ? Theme.say("ACQVIRE", "INSTALL")
            : root.armed ? Theme.say("CERTE?", "SURE?")
            : Theme.say("ABICE", "REMOVE")
        onClicked: root.act()
    }

    // Work in hand: a sunk channel filling with gilt, and a way to stop it.
    RowLayout {
        anchors.fill: parent
        visible: root.busy
        spacing: 8

        Niche {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 4 }
                width: Math.max(0, (parent.width - 8) * Math.min(1, listener.progress / 100))
                color: Theme.giltDeep
                opacity: 0.85
                Behavior on width { NumberAnimation { duration: 250 } }
            }
            Carved {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 10 }
                text: listener.statusText !== "" ? listener.statusText : Theme.say("in opere", "working")
                family: Theme.serif
                size: root.compact ? 13 : 15
                weight: Font.Medium
                italic: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Lapis {
            Layout.fillHeight: true
            visible: listener.isCancellable
            text: Theme.say("OMITTE", "CANCEL")
            size: 11
            onClicked: listener.cancel()
        }
    }
}
