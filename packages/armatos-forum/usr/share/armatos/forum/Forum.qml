import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover
import org.kde.discover.app as DiscoverApp

// FORVM, the market of the empire. Discover's engine (libdiscover, with
// PackageKit, Flatpak and fwupd behind it) under an Armatos face: a porphyry
// column of stalls on the left, marble pages on the right.
//
// Discover's C++ drives the window through a few properties, so these keep
// its names: currentTopLevel, top<Mode>Comp, leftPage and describeSources.
Window {
    id: forum

    objectName: "DiscoverMainWindow"
    title: "Forum"
    width: 1240
    height: 860
    minimumWidth: 760
    minimumHeight: 520
    visible: true
    color: Theme.night

    // ---- What Discover's C++ expects -------------------------------------

    property string currentTopLevel
    readonly property string topBrowsingComp: "tabernae"
    readonly property string topInstalledComp: "possessa"
    readonly property string topSearchComp: "quaere"
    readonly property string topUpdateComp: "tributum"
    readonly property string topSourcesComp: "fontes"
    readonly property string topAboutComp: "deforo"
    readonly property string describeSources: ""
    readonly property Item leftPage: stack.length > 0 ? stack[0] : null
    // main.cpp asks pageStack.depth to decide whether to open the front page.
    readonly property QtObject pageStack: QtObject {
        readonly property int depth: forum.stack.length
    }

    // ---- Our own page stack ------------------------------------------------

    property var stack: []
    readonly property Item topPage: stack.length > 0 ? stack[stack.length - 1] : null
    readonly property string current: {
        const t = currentTopLevel;
        return t === "" || t.endsWith(".qml") ? "tabernae" : t;
    }
    property bool ready: false

    readonly property var pageFor: ({
        "tabernae": "Tabernae",
        "possessa": "Possessa",
        "quaere": "Merces",
        "tributum": "Tributum",
        "fontes": "Fontes",
        "deforo": "DeForo"
    })

    function push(name, props) {
        const component = Qt.createComponent(Qt.resolvedUrl(name + ".qml"));
        if (component.status !== Component.Ready) {
            console.warn("Forum: cannot build", name, component.errorString());
            return null;
        }
        const page = component.createObject(stage, Object.assign({ forum: forum }, props || {}));
        if (!page) {
            console.warn("Forum: cannot raise", name);
            return null;
        }
        stack = stack.concat([page]);
        return page;
    }

    function pop() {
        if (stack.length <= 1)
            return;
        const page = stack[stack.length - 1];
        stack = stack.slice(0, stack.length - 1);
        page.destroy();
    }

    function reset(name, props) {
        const old = stack;
        stack = [];
        for (const page of old)
            page.destroy();
        if (name)
            push(name, props);
    }

    function raiseTop() {
        const t = currentTopLevel;
        if (t.endsWith("LoadingPage.qml"))
            reset("Exspecta");
        else if (t === "quaere")
            reset("Merces", { isSearch: true });
        else
            reset(pageFor[t] || "Tabernae");   // not "current": its binding may lag
        if (t === "quaere")
            searchField.forceActiveFocus();
    }

    // Open one of the column's stalls; opening the one you are in again
    // takes you back to its first page.
    function openTop(name) {
        if (currentTopLevel === name)
            raiseTop();
        else
            currentTopLevel = name;
    }

    function openCategory(categoryPtr) {
        openTop("tabernae");
        push("Merces", { category: categoryPtr });
    }

    function search(text) {
        if (topPage && topPage.isSearch) {
            topPage.search = text;
        } else if (text.length > 1) {
            push("Merces", { search: text, isSearch: true });
        }
    }

    onCurrentTopLevelChanged: if (ready) raiseTop()
    Component.onCompleted: {
        ready = true;
        raiseTop();
    }

    // ---- Edicts: messages from the engine --------------------------------

    function proclaim(message) {
        if (!message)
            return;
        for (let i = 0; i < edicts.count; ++i) {
            if (edicts.get(i).message === String(message))
                return;
        }
        edicts.append({ message: String(message) });
        app.restore();
    }

    ListModel { id: edicts }

    // Petitions: a transaction that needs the Imperator's word first.
    property var petition: null

    // ---- The engine's signals -----------------------------------------------

    Connections {
        target: app
        function onOpenApplicationInternal(resource) {
            forum.openTop("tabernae");
            forum.push("Res", { application: resource });
        }
        function onListMimeInternal(mime) {
            forum.openTop("tabernae");
            forum.push("Merces", { mimeTypeFilter: mime, title: app.mimeTypeComment(mime).toUpperCase() });
        }
        function onListCategoryInternal(category) {
            forum.openCategory(category);
        }
        function onOpenSearch(text) {
            forum.openTop("tabernae");
            searchField.text = text;
            forum.push("Merces", { search: text, isSearch: true });
        }
        function onOpenErrorPage(message, explanation, buttonText, buttonIcon, buttonUrl) {
            forum.openTop("tabernae");
            forum.push("Calamitas", { message, explanation, buttonText, buttonUrl });
        }
        function onUnableToFind(resid) {
            forum.proclaim(Theme.say("Nemo mercator hoc nomine respondet: ", "No merchant answers to that name: ") + resid);
            forum.openTop("tabernae");
        }
    }

    Connections {
        target: Discover.ResourcesModel
        function onSwitchToUpdates() {
            forum.openTop("tributum");
        }
        function onPassiveMessage(message) {
            forum.proclaim(message);
        }
    }

    Instantiator {
        model: Discover.TransactionModel
        delegate: Connections {
            required property Discover.Transaction transaction
            target: transaction
            function onProceedRequest(title, description) {
                forum.petition = { transaction, title, description };
                app.restore();
            }
            function onPassiveMessage(message) {
                forum.proclaim(message);
            }
            function onDistroErrorMessage(message, actions) {
                forum.proclaim(message);
            }
            function onWebflowStarted(url) {
                Qt.openUrlExternally(url);
            }
        }
    }

    // No sleeping while goods are on the road.
    DiscoverApp.PowerManagementInterface {
        reason: Discover.TransactionModel.mainTransactionText
        preventSleep: Discover.TransactionModel.count > 0
    }

    // ---- Keys ------------------------------------------------------------

    Shortcut { sequences: [StandardKey.Find]; onActivated: searchField.forceActiveFocus() }
    Shortcut { sequences: [StandardKey.Back, "Escape"]; onActivated: forum.pop() }
    Shortcut { sequences: [StandardKey.Refresh]; onActivated: Discover.ResourcesModel.updateAction.trigger() }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onClicked: forum.pop()
    }

    // ---- The building --------------------------------------------------------

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Columna {
            Layout.fillHeight: true
            Layout.preferredWidth: 256
            forum: forum
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // The header: a way back, the page's name, and the search niche.
            Marble {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                z: 2
                seed: 0.31

                Bevel {}

                RowLayout {
                    anchors { fill: parent; leftMargin: 22; rightMargin: 22; bottomMargin: Theme.mouldingHeight }
                    spacing: 18

                    Lapis {
                        visible: forum.stack.length > 1
                        text: "‹ " + Theme.say("REDI", "BACK")
                        size: 12
                        onClicked: forum.pop()
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Carved {
                            Layout.fillWidth: true
                            text: forum.topPage && forum.topPage.title ? forum.topPage.title : "FORVM"
                            size: 22
                            spacing: 0.14
                            elide: Text.ElideRight
                        }
                        Gloss {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: forum.topPage && forum.topPage.gloss ? forum.topPage.gloss : ""
                            size: 14
                            elide: Text.ElideRight
                        }
                    }

                    Niche {
                        Layout.preferredWidth: Math.min(380, forum.width * 0.3)
                        Layout.preferredHeight: 42

                        TextInput {
                            id: searchField
                            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.serif
                            font.pixelSize: 19
                            color: Theme.ink
                            selectionColor: Theme.giltDeep
                            selectedTextColor: Theme.pale
                            clip: true
                            onTextEdited: hush.restart()
                            Keys.onReturnPressed: { hush.stop(); forum.search(text); }
                            Keys.onEnterPressed: { hush.stop(); forum.search(text); }
                            Keys.onEscapePressed: { text = ""; forum.search(""); focus = false; }
                        }
                        Gloss {
                            visible: searchField.text === "" && !searchField.activeFocus
                            anchors { left: parent.left; leftMargin: 15; verticalCenter: parent.verticalCenter }
                            text: Theme.say("Quaere merces…", "Search for software…")
                            size: 18
                        }
                        Timer {
                            id: hush
                            interval: 450
                            onTriggered: forum.search(searchField.text)
                        }
                    }
                }

                Moulding {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                }
            }

            // The page itself.
            Marble {
                Layout.fillWidth: true
                Layout.fillHeight: true
                seed: 0.72

                Item {
                    id: stage
                    anchors.fill: parent
                }

                // Edicts: one porphyry tablet per message, newest at the bottom.
                Column {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 22 }
                    spacing: 10
                    z: 5

                    Repeater {
                        model: edicts
                        delegate: Slab {
                            required property string message
                            required property int index
                            porphyry: true
                            width: parent.width
                            height: edictText.implicitHeight + 28

                            // Edicts are posted, read, and taken down.
                            Timer {
                                running: true
                                interval: 25000
                                onTriggered: edicts.remove(index)
                            }

                            Carved {
                                id: edictText
                                anchors { left: parent.left; right: dismiss.left; verticalCenter: parent.verticalCenter; leftMargin: 18; rightMargin: 12 }
                                text: Theme.plain(message)
                                family: Theme.serif
                                size: 16
                                weight: Font.Medium
                                tone: "gilt"
                                wrapMode: Text.Wrap
                                maximumLineCount: 6
                            }
                            Lapis {
                                id: dismiss
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
                                text: Theme.say("DIMITTE", "DISMISS")
                                size: 11
                                onClicked: edicts.remove(index)
                            }
                        }
                    }
                }
            }
        }
    }

    // A petition: the engine wants consent before it goes on.
    Rectangle {
        anchors.fill: parent
        visible: forum.petition !== null
        color: Qt.rgba(0.06, 0.03, 0.02, 0.55)
        z: 20

        MouseArea { anchors.fill: parent }

        Slab {
            moulding: true
            width: Math.min(620, parent.width - 80)
            height: petitionBody.implicitHeight + Theme.mouldingHeight + 48
            anchors.centerIn: parent

            ColumnLayout {
                id: petitionBody
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 30; topMargin: 22 }
                spacing: 14

                Carved {
                    Layout.alignment: Qt.AlignHCenter
                    text: Theme.say("PETITIO", "A REQUEST")
                    size: 16
                    spacing: 0.2
                    tone: "red"
                }
                Carved {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: forum.petition ? forum.petition.title : ""
                    family: Theme.serif
                    size: 20
                    weight: Font.Medium
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                }
                Text {
                    Layout.fillWidth: true
                    text: forum.petition ? forum.petition.description : ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    font.family: Theme.serif
                    font.pixelSize: 16
                    color: Theme.ink
                    style: Text.Sunken
                    styleColor: Qt.rgba(1, 1, 1, 0.8)
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    Lapis {
                        Layout.fillWidth: true
                        text: Theme.say("NEGA", "CANCEL")
                        onClicked: {
                            forum.petition.transaction.cancel();
                            forum.petition = null;
                        }
                    }
                    Lapis {
                        Layout.fillWidth: true
                        porphyry: true
                        text: Theme.say("CONCEDE", "PROCEED")
                        onClicked: {
                            forum.petition.transaction.proceed();
                            forum.petition = null;
                        }
                    }
                }
            }
        }
    }

    // A screenshot, shown large.
    property url picture: ""
    Rectangle {
        anchors.fill: parent
        visible: forum.picture.toString() !== ""
        color: Qt.rgba(0.04, 0.02, 0.02, 0.88)
        z: 30

        MouseArea {
            anchors.fill: parent
            onClicked: forum.picture = ""
        }
        Image {
            anchors { fill: parent; margins: 48 }
            source: forum.picture
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            mipmap: true
        }
        Carved {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 14 }
            text: Theme.say("PREME VT CLAVDAS", "CLICK TO CLOSE")
            size: 11
            spacing: 0.2
            tone: "pale"
        }
    }
}
