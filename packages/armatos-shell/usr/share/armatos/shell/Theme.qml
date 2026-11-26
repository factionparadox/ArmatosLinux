pragma Singleton
import QtQuick
import Quickshell

// Marmor: the Armatos look. Colours, faces, textures and the Roman reckoning.
Singleton {
    id: theme

    // Stone and ink
    readonly property color ink: "#3A2F29"        // letters cut into marble
    readonly property color faint: "#6A615A"      // worn letters (empty workspaces)
    readonly property color red: "#7A0000"        // rubricated letters
    readonly property color gilt: "#EAC55E"       // gilded letters on porphyry
    readonly property color giltDeep: "#8A6518"
    readonly property color night: "#16110F"
    readonly property color marbleBase: "#E9E5DF"
    readonly property color porphyryBase: "#5E0E18"
    readonly property color highlight: Qt.rgba(1, 1, 1, 0.85)
    readonly property color cutShadow: Qt.rgba(0, 0, 0, 0.30)

    // Faces
    readonly property string caps: "Cinzel"
    readonly property string serif: "EB Garamond"
    readonly property string mono: "JetBrains Mono"

    // Sizes (logical pixels; the 13 Pro runs at scale 2)
    readonly property int barHeight: 52
    readonly property int mouldingHeight: 14

    function asset(name) {
        return Qt.resolvedUrl("assets/" + name);
    }

    // ---- Numerals -------------------------------------------------------

    function roman(value) {
        let n = Math.round(value);
        if (n <= 0)
            return "N";         // nulla, as the computists wrote zero
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

    // A reading for the Titulus: Roman unless the Imperator chose Arabic.
    function num(value) {
        return Settings.numerals === "arabici" ? String(Math.round(value)) : roman(value);
    }

    // ---- The Roman calendar ----------------------------------------------

    readonly property var months: ["IAN", "FEB", "MAR", "APR", "MAI", "IVN", "IVL", "AVG", "SEP", "OCT", "NOV", "DEC"]
    readonly property var monthsEn: ["January", "February", "March", "April", "May", "June", "July",
                                     "August", "September", "October", "November", "December"]

    function aucYear(date) {
        return date.getFullYear() + 753;
    }

    // "A·D·VI·KAL·DEC": days are counted inclusively back from the next
    // Kalends, Nones or Ides. The Nones fall on the 7th and the Ides on the
    // 15th in March, May, July and October; otherwise on the 5th and 13th.
    function romanDate(date) {
        const d = date.getDate();
        const m = date.getMonth();
        const late = [2, 4, 6, 9].includes(m);
        const nones = late ? 7 : 5;
        const ides = late ? 15 : 13;
        const daysInMonth = new Date(date.getFullYear(), m + 1, 0).getDate();
        const mon = months[m];
        const next = months[(m + 1) % 12];

        function count(n, mark, month) {
            if (n === 2)
                return "PRID·" + mark + "·" + month;
            return "A·D·" + roman(n) + "·" + mark + "·" + month;
        }

        if (d === 1)
            return "KAL·" + mon;
        if (d < nones)
            return count(nones - d + 1, "NON", mon);
        if (d === nones)
            return "NON·" + mon;
        if (d < ides)
            return count(ides - d + 1, "ID", mon);
        if (d === ides)
            return "ID·" + mon;
        return count(daysInMonth - d + 2, "KAL", next);
    }

    function dateLine(date) {
        if (Settings.lingua === "en")
            return date.getDate() + " " + monthsEn[date.getMonth()];
        return romanDate(date);
    }

    // ---- Voice -----------------------------------------------------------

    // Latin by default; the English toggle swaps the explanatory lines while
    // the carved labels (SONUS, LUX, VIS) stay Latin, as in the design.
    function say(latin, english) {
        return Settings.lingua === "en" ? english : latin;
    }
}
