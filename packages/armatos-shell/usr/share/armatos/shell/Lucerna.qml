pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Lucerna, the oil lamp: from sunset the screen warms to lamplight.
// Runs wlsunset with fixed hours, so no location is needed.
Singleton {
    Process {
        running: Settings.lucerna
        command: ["wlsunset", "-t", "3400", "-T", "6500", "-S", "07:00", "-s", "19:00", "-d", "1800"]
    }
}
