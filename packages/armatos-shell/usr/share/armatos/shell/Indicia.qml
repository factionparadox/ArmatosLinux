pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Networking

// The readings shown on the Titulus: VIS (battery), SONUS (volume),
// LUX (brightness) and RETE (network).
Singleton {
    id: indicia

    // ---- VIS: battery ----------------------------------------------------
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: !!battery && battery.isPresent && battery.isLaptopBattery
    readonly property real vis: hasBattery ? battery.percentage * 100 : 0     // UPower gives 0..1
    readonly property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging
    readonly property bool full: hasBattery && battery.state === UPowerDeviceState.FullyCharged
    readonly property bool onBattery: UPower.onBattery

    function visLine() {
        if (!hasBattery)
            return "";
        let line = "VIS " + Theme.num(vis);
        if (full)
            return line + " · " + Theme.say("plena", "full");
        if (charging) {
            line += " · " + Theme.say("reficitur", "charging");
            if (battery.timeToFull > 0)
                line += " · " + duration(battery.timeToFull) + Theme.say(" ad plenum", " to full");
        } else if (battery.timeToEmpty > 0) {
            line += " · " + duration(battery.timeToEmpty) + Theme.say(" reliquae", " left");
        }
        return line;
    }

    function duration(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        if (Settings.lingua === "en")
            return h > 0 ? h + " h " + m + " min" : m + " min";
        return h > 0 ? Theme.roman(h) + " h " + Theme.roman(m) + " m" : Theme.roman(m) + " m";
    }

    // ---- SONUS: volume -----------------------------------------------------
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasSink: !!sink && !!sink.audio
    readonly property real sonus: hasSink ? sink.audio.volume * 100 : 0
    readonly property bool muted: hasSink && sink.audio.muted

    PwObjectTracker { objects: indicia.sink ? [indicia.sink] : [] }

    readonly property var devices: Networking.devices ? Networking.devices.values : []

    function setSonus(percent) {
        if (!hasSink)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.0, percent / 100));
    }
    function toggleMute() {
        if (hasSink)
            sink.audio.muted = !sink.audio.muted;
    }

    // ---- LUX: brightness -----------------------------------------------------
    // brightnessctl reads the backlight; writes go through logind, so no
    // special group is needed. Polled lightly, and at once after a change.
    property bool hasBacklight: false
    property real lux: 0

    function setLux(percent) {
        const p = Math.max(1, Math.min(100, Math.round(percent)));
        lux = p;
        Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", p + "%"]);
    }

    Process {
        id: luxRead
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                // name,class,current,percent%,max
                const f = text.trim().split(",");
                if (f.length >= 5 && f[1] === "backlight") {
                    indicia.hasBacklight = true;
                    indicia.lux = parseInt(f[3]);
                } else {
                    indicia.hasBacklight = false;
                }
            }
        }
    }
    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: luxRead.running = true
    }
    function refreshLux() { luxRead.running = true; }

    // ---- RETE: network ---------------------------------------------------------
    readonly property var wifiDevice: {
        for (const d of devices)
            if (d.type === DeviceType.Wifi)
                return d;
        return null;
    }
    readonly property var wiredDevice: {
        for (const d of devices)
            if (d.type === DeviceType.Wired && d.connected)
                return d;
        return null;
    }
    readonly property var wifiNetwork: {
        if (!wifiDevice)
            return null;
        for (const n of wifiDevice.networks.values)
            if (n.connected)
                return n;
        return null;
    }
    readonly property string rete: wifiNetwork ? (wifiNetwork.name || "WI-FI")
                                 : wiredDevice ? Theme.say("FILVM", "WIRED")
                                 : Theme.say("NVLLA", "NONE")
    readonly property bool online: wifiNetwork !== null || wiredDevice !== null
}
