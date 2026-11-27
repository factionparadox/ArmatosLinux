pragma Singleton
import QtQuick
import QtCore

// Marmor for Forum. The same stone, ink and faces as the shell; Forum runs
// in Discover's QML engine, so it can't use Quickshell and keeps its own
// copy. The shell's settings (numerals, lingua) are read from its state file.
QtObject {
    id: theme

    // Stone and ink
    readonly property color ink: "#3A2F29"
    readonly property color faint: "#6A615A"
    readonly property color red: "#7A0000"
    readonly property color gilt: "#EAC55E"
    readonly property color giltDeep: "#8A6518"
    readonly property color night: "#16110F"
    readonly property color marbleBase: "#E9E5DF"
    readonly property color porphyryBase: "#5E0E18"
    readonly property color pale: "#EDE6DC"

    // Faces
    readonly property string caps: "Cinzel"
    readonly property string serif: "EB Garamond"
    readonly property string mono: "JetBrains Mono"

    readonly property int mouldingHeight: 14

    // Textures come from the shell's package; the marble slab is Forum's own.
    function asset(name) {
        return "file:///usr/share/armatos/shell/assets/" + name;
    }
    readonly property url slab: Qt.resolvedUrl("marmor-slab.jpg")

    // A steady number in [0, 1) for a name, so a piece of stone cut for a
    // program is cut from the same place every time it is shown.
    function hash(text) {
        let h = 2166136261;
        const s = String(text || "");
        for (let i = 0; i < s.length; ++i) {
            h ^= s.charCodeAt(i);
            h = Math.imul(h, 16777619) >>> 0;
        }
        return h / 4294967296;
    }

    // ---- The shell's settings --------------------------------------------

    property string numerals: "romani"     // or "arabici"
    property string lingua: "la"           // or "en"

    readonly property string settingsFile: {
        const state = StandardPaths.writableLocation(StandardPaths.GenericStateLocation).toString();
        return (state !== "" ? state : StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/state")
            + "/armatos/shell.json";
    }

    function reload() {
        const request = new XMLHttpRequest();
        request.onreadystatechange = function () {
            if (request.readyState !== XMLHttpRequest.DONE || !request.responseText)
                return;
            try {
                const saved = JSON.parse(request.responseText);
                theme.numerals = saved.numerals || "romani";
                theme.lingua = saved.lingua || "la";
            } catch (e) {}
        };
        request.open("GET", settingsFile);
        request.send();
    }

    // The Tabula can flip the language while Forum is open.
    property Timer watch: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: theme.reload()
    }

    // ---- Words and numbers -------------------------------------------------

    function say(latin, english) {
        return lingua === "en" ? english : latin;
    }

    function roman(value) {
        let n = Math.round(value);
        if (n <= 0)
            return "N";
        const table = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
                       [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
        let out = "";
        for (const [v, s] of table) {
            while (n >= v) {
                out += s;
                n -= v;
            }
        }
        return out;
    }

    function num(value) {
        return numerals === "arabici" ? String(Math.round(value)) : roman(value);
    }

    // Engine messages come as HTML; carve them as plain words.
    function plain(html) {
        return String(html || "").replace(/<br\s*\/?>|<\/p>|<\/?nl\/?>/gi, " ").replace(/<[^>]*>/g, "")
            .replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/\s+/g, " ").trim();
    }

    // Discover's category names (in English) and what the Forum's stalls are
    // called. Anything not listed is carved as it comes.
    readonly property var stalls: ({
        "All Applications": "OMNIA",
        "Utilities": "INSTRVMENTA",
        "Accessibility": "ADITVS",
        "Development": "FABRICA",
        "Education": "SCHOLA",
        "Science & Math": "SCIENTIA",
        "Games": "LVDI",
        "Graphics": "PICTVRA",
        "Internet": "RETE",
        "Multimedia": "SPECTACVLA",
        "Office": "TABVLARIVM",
        "System": "MACHINA",
        "Fonts": "LITTERAE",
        "Hardware Drivers": "AVRIGAE",
        "Debugging": "EMENDATIO",
        "Graphic Interface Design": "FORMAE",
        "IDEs": "OFFICINAE",
        "Localization": "INTERPRETES",
        "Profiling": "MENSVRAE",
        "Web Development": "TELAE",
        "Astronomy": "ASTRONOMIA",
        "Biology": "BIOLOGIA",
        "Chemistry": "CHEMIA",
        "Computer Science and Robotics": "AVTOMATA",
        "Electronics": "ELECTRICA",
        "Engineering": "MACHINATIO",
        "Geography": "GEOGRAPHIA",
        "Geology": "GEOLOGIA",
        "Mathematics": "MATHEMATICA",
        "Physics": "PHYSICA",
        "Arcade": "CIRCVS",
        "Board Games": "TABVLAE",
        "Card Games": "CHARTAE",
        "Puzzles": "AENIGMATA",
        "Role Playing": "PERSONAE",
        "Simulation": "SIMVLACRA",
        "Strategy": "STRATEGEMATA",
        "Sports": "CERTAMINA",
        "Action": "PROELIA",
        "Emulators": "IMITATORES",
        "3D": "SCVLPTVRA",
        "Drawing": "DELINEATIO",
        "Painting and Editing": "PICTORES",
        "Photography": "IMAGINES",
        "Publishing": "EDITIO",
        "Scanning and OCR": "LECTIO",
        "Viewers": "INSPECTIO",
        "Chat": "COLLOQVIA",
        "File Sharing": "PERMVTATIO",
        "Mail": "EPISTVLAE",
        "Web Browsers": "EXPLORATORES",
        "Audio and Video Editors": "SONVS ET VISVS",
        "Audio Players": "MVSICA",
        "Video Players": "THEATRVM",
        "CD and DVD": "DISCI",
        "Applications": "OPERA",
        "Application Support": "FVLCRA",
        "System Software": "FVNDAMENTA",
        "Addons": "ADDITAMENTA"
    })

    function stall(name) {
        if (!name)
            return "";
        return stalls[name] || name.toUpperCase();
    }

    // Plasma's own add-ons mean nothing on Armatos.
    function hiddenStall(name) {
        return name === "Plasma Addons" || name === "Plasma Widgets";
    }

    // Flatpak goods are foreign; everything from APT is the empire's own.
    function isForeign(resource) {
        return !!resource && !!resource.backend && resource.backend.name === "flatpak-backend";
    }

    function originLine(resource) {
        if (!resource)
            return "";
        if (isForeign(resource))
            return "PEREGRINA";
        if (resource.backend && resource.backend.name === "fwupd-backend")
            return say("FERRAMENTA", "FIRMWARE");
        return (resource.displayOrigin || "").toUpperCase();
    }
}
