import QtQuick
import Quickshell
import Quickshell.Wayland

// The city behind everything: the Atlas art on the background layer.
// Put your own at ~/.local/share/armatos/wallpaper.jpg (or .png) to change it.
PanelWindow {
    id: wall
    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.night
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "armatos-wallpaper"

    // If Mango drops the surface (its output went away and came back, as
    // on a VT switch), raise it again rather than leave the screen bare.
    onVisibleChanged: if (!visible) revive.restart()
    Timer {
        id: revive
        interval: 1500
        onTriggered: wall.visible = true
    }

    readonly property string own: Quickshell.env("HOME") + "/.local/share/armatos/wallpaper"

    Image {
        id: art
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: wall.width * (wall.screen ? wall.screen.devicePixelRatio : 1)
        property int attempt: 0
        readonly property var candidates: ["file://" + wall.own + ".jpg", "file://" + wall.own + ".png", Theme.asset("atlas.jpg")]
        source: candidates[attempt]
        onStatusChanged: if (status === Image.Error && attempt < candidates.length - 1) attempt++
    }
}
