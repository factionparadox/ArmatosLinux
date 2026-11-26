pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The compositor, MangoWC, through its own IPC (mmsg). Two watches stream
// JSON lines: the tags (our workspaces I-IX) of every monitor, and the
// focused window.
Singleton {
    id: mango

    property var monitors: ({})          // output name -> [{index, is_active, is_urgent, client_count}]
    property string title: ""
    property string appId: ""
    property string focusedMonitor: ""
    property bool online: false

    function tagsFor(output) {
        if (monitors[output])
            return monitors[output];
        const names = Object.keys(monitors);
        return names.length ? monitors[names[0]] : [];
    }

    function dispatch(command) {
        Quickshell.execDetached(["mmsg", "dispatch", command]);
    }

    function view(tag) { dispatch("view," + tag + ",0"); }
    function colosseum() { dispatch("overcircle,next"); }
    function quit() { dispatch("quit"); }

    Process {
        id: tagWatch
        command: ["mmsg", "watch", "all-tags"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const reply = JSON.parse(line);
                    const map = {};
                    for (const entry of reply.all_tags)
                        map[entry.monitor] = entry.tags;
                    mango.monitors = map;
                    mango.online = true;
                } catch (e) {}
            }
        }
        onExited: { mango.online = false; retry.restart(); }
    }

    Process {
        id: focusWatch
        command: ["mmsg", "watch", "focusing-client"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const c = JSON.parse(line);
                    mango.title = c.title ?? "";
                    mango.appId = c.appid ?? "";
                    if (c.monitor)
                        mango.focusedMonitor = c.monitor;
                } catch (e) {}
            }
        }
        onExited: retry.restart()
    }

    // If Mango restarts (or the watch drops), reconnect.
    Timer {
        id: retry
        interval: 2000
        onTriggered: {
            if (!tagWatch.running) tagWatch.running = true;
            if (!focusWatch.running) focusWatch.running = true;
        }
    }
}
