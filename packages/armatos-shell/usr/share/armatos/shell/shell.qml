//@ pragma UseQApplication
//@ pragma IconTheme Papirus
import QtQuick
import Quickshell
import Quickshell.Io

// Armatos Linux: the Marmor shell for MangoWC.
// Run with:  qs -c armatos     (the session starts it for you)
ShellRoot {
    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }
    Variants {
        model: Quickshell.screens
        Titulus {}
    }

    Launcher {}
    Tabula {}
    Vale {}
    Edicta {}
    Porta {}
    Praetoriani {}

    // Light the night lamp if it was left lit.
    readonly property var lamp: Lucerna

    // Orders from keybinds:  qs -c armatos ipc call <target> <function>
    IpcHandler {
        target: "launcher"
        function toggle(): void { Shell.toggleLauncher(null); }
    }
    IpcHandler {
        target: "tabula"
        function toggle(): void { Shell.toggleTabula(null); }
    }
    IpcHandler {
        target: "vale"
        function toggle(): void { Shell.toggleVale(null); }
    }
    IpcHandler {
        target: "porta"
        function lock(): void { Shell.lock(); }
        function sleep(): void { Shell.sleep(); }
    }
    IpcHandler {
        target: "numerals"
        function toggle(): void { Settings.numerals = Settings.numerals === "romani" ? "arabici" : "romani"; }
    }
    IpcHandler {
        target: "lingua"
        function toggle(): void { Settings.lingua = Settings.lingua === "la" ? "en" : "la"; }
    }
}
