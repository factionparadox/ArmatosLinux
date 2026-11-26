pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The Imperator's standing orders, kept in ~/.local/state/armatos/shell.json
// so they survive restarts. Edit the file by hand if you like; the shell
// picks the change up straight away.
Singleton {
    id: settings

    property alias numerals: adapter.numerals     // "romani" or "arabici"
    property alias lingua: adapter.lingua         // "la" or "en"
    property alias silentium: adapter.silentium   // do not disturb
    property alias lucerna: adapter.lucerna       // night light

    FileView {
        id: file
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/armatos/shell.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property string numerals: "romani"
            property string lingua: "la"
            property bool silentium: false
            property bool lucerna: false
        }
    }
}
