import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover

// Goods in a stall, or found by a search. The filters are Discover's own
// ResourcesProxyModel; the page only sets what it was opened with.
Pagina {
    id: page

    property alias category: goods.filteredCategory
    property alias search: goods.search
    property alias mimeTypeFilter: goods.mimeTypeFilter
    property alias originFilter: goods.originFilter
    property alias extending: goods.extending
    property alias allBackends: goods.allBackends
    property string heading: ""
    readonly property var categoryObject: goods.filteredCategory ? Discover.CategoryModel.get(goods.filteredCategory) : null

    // NameRole, SortableRatingRole, SizeRole, ReleaseDateRole or, for
    // searches, SearchRelevanceRole.
    property int order: -1
    readonly property int sortRole: order >= 0 ? order
        : (goods.search.length > 0 ? Discover.ResourcesProxyModel.SearchRelevanceRole : Discover.ResourcesProxyModel.NameRole)

    title: heading !== "" ? heading
        : categoryObject ? Theme.stall(categoryObject.name)
        : isSearch ? Theme.say("QVAERE", "SEARCH")
        : "MERCES"
    gloss: {
        if (goods.busy)
            return Theme.say("Merces quaeruntur…", "Looking through the goods…");
        const n = goods.count && goods.count.valid ? goods.count.number : 0;
        if (goods.search.length > 0)
            return "«" + goods.search + "» · " + (n > 0 ? Theme.num(n) + Theme.say(" inventa", " found") : Theme.say("nihil inventum", "nothing found"));
        if (categoryObject)
            return (Theme.lingua === "en" ? "" : categoryObject.name + " · ") + Theme.num(n) + Theme.say(" merces", " items");
        return n > 0 ? Theme.num(n) + Theme.say(" merces", " items") : "";
    }

    Discover.ResourcesProxyModel {
        id: goods
        sortRole: page.sortRole
        sortOrder: sortRole === Discover.ResourcesProxyModel.NameRole ? Qt.AscendingOrder : Qt.DescendingOrder
    }

    ColumnLayout {
        anchors { fill: parent; leftMargin: 34; rightMargin: 34; topMargin: 20 }
        spacing: 14

        // Sub-stalls and the order of the goods.
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: page.categoryObject ? page.categoryObject.subcategories : []
                    delegate: Lapis {
                        required property var modelData
                        readonly property var sub: Discover.CategoryModel.get(modelData)
                        visible: !!sub && sub.visible
                        text: sub ? (Theme.lingua === "en" ? sub.name.toUpperCase() : Theme.stall(sub.name)) : ""
                        size: 11
                        implicitHeight: 32
                        onClicked: page.forum.push("Merces", { category: modelData })
                    }
                }
            }

            Carved { text: Theme.say("ORDO", "ORDER"); size: 11; spacing: 0.25; tone: "faint" }
            Repeater {
                model: [
                    { role: Discover.ResourcesProxyModel.SearchRelevanceRole, la: "CONGRVENTIA", en: "RELEVANCE", search: true },
                    { role: Discover.ResourcesProxyModel.NameRole, la: "NOMEN", en: "NAME" },
                    { role: Discover.ResourcesProxyModel.SortableRatingRole, la: "FAMA", en: "RATING" },
                    { role: Discover.ResourcesProxyModel.SizeRole, la: "MAGNITVDO", en: "SIZE" },
                    { role: Discover.ResourcesProxyModel.ReleaseDateRole, la: "NOVITAS", en: "NEWEST" }
                ]
                delegate: Lapis {
                    required property var modelData
                    visible: !modelData.search || goods.search.length > 0
                    porphyry: page.sortRole === modelData.role
                    text: Theme.say(modelData.la, modelData.en)
                    size: 10
                    implicitHeight: 30
                    onClicked: page.order = modelData.role
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors { fill: parent; rightMargin: 14 }
                clip: true
                model: goods
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 600
                reuseItems: false
                delegate: Merx {
                    forum: page.forum
                }
                footer: Item { width: 1; height: 24 }
            }

            Rail {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom; bottomMargin: 20 }
                flickable: list
            }

            // Empty, waiting, or not yet asked.
            ColumnLayout {
                anchors.centerIn: parent
                visible: list.count === 0
                spacing: 8
                width: Math.min(560, parent.width - 40)

                Carved {
                    Layout.alignment: Qt.AlignHCenter
                    text: goods.busy ? Theme.say("EXSPECTA…", "ONE MOMENT…")
                        : page.isSearch && goods.search.length === 0 ? Theme.say("QVID QVAERIS?", "WHAT ARE YOU LOOKING FOR?")
                        : Theme.say("NIHIL INVENTVM", "NOTHING FOUND")
                    size: 22
                    spacing: 0.22
                    tone: goods.busy ? "ink" : "faint"
                }
                Gloss {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    visible: !goods.busy
                    text: page.isSearch && goods.search.length === 0
                        ? Theme.say("Scribe nomen in quaestione supra.", "Type a name into the search niche above.")
                        : goods.search.length > 0 && page.categoryObject
                        ? Theme.say("In hac taberna non est. Quaere in toto foro.", "Not in this stall. Search the whole Forum instead.")
                        : ""
                    size: 17
                }
                Lapis {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !goods.busy && goods.search.length > 0 && !!page.categoryObject
                    text: Theme.say("QVAERE IN TOTO FORO", "SEARCH EVERYWHERE")
                    onClicked: page.forum.push("Merces", { search: goods.search, isSearch: true })
                }
            }
        }
    }
}
