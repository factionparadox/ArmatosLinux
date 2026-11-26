pragma Singleton
import QtQuick
import Quickshell

// Which panels are open, and on which screen.
Singleton {
    id: shell

    property bool launcher: false
    property bool tabula: false
    property bool vale: false
    property bool locked: false
    property var screen: null       // where the last panel was summoned

    // The screen Mango has focus on, else the first.
    function focusedScreen() {
        for (const s of Quickshell.screens)
            if (s.name === Mango.focusedMonitor)
                return s;
        return Quickshell.screens[0];
    }

    function closeAll() {
        launcher = false;
        tabula = false;
        vale = false;
    }

    function toggleLauncher(onScreen) {
        const open = !launcher;
        closeAll();
        screen = onScreen ?? focusedScreen();
        launcher = open;
    }

    function toggleTabula(onScreen) {
        const open = !tabula;
        closeAll();
        screen = onScreen ?? focusedScreen();
        tabula = open;
    }

    function toggleVale(onScreen) {
        const open = !vale;
        closeAll();
        screen = onScreen ?? focusedScreen();
        vale = open;
    }

    function lock() {
        closeAll();
        locked = true;
    }

    // Seal the gates first, then sleep, so the machine wakes locked.
    function sleep() {
        lock();
        sleepTimer.restart();
    }

    Timer {
        id: sleepTimer
        interval: 600
        onTriggered: Quickshell.execDetached(["systemctl", "suspend"])
    }
}
