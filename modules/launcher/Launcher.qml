import Quickshell
import Quickshell.Widgets
import QtQuick
import Qt.labs.folderlistmodel
import qs.components
import qs.services
import qs.utils
import "../../utils/Calc.js" as Calc

// Launcher yang muncul dari tepi bawah, dengan mode prefix:
//   (kosong) aplikasi   = kalkulator   > perintah shell   : wallpaper
Item {
    id: root

    property bool shown: false

    readonly property string query: input.text
    readonly property string mode: query.startsWith("=") ? "calc" : query.startsWith(">") ? "run" : query.startsWith(":") ? "wall" : "apps"
    readonly property string term: mode === "apps" ? query.trim() : query.slice(1).trim()
    readonly property int rowHeight: mode === "wall" ? 64 : 56
    readonly property int maxRows: Config.launcherMaxResults
    readonly property var results: {
        switch (mode) {
        case "calc":
            {
                const r = Calc.evaluate(term);
                return r === null ? [] : [
                    {
                        kind: "calc",
                        title: String(r),
                        subtitle: "Enter untuk menyalin"
                    }
                ];
            }
        case "run":
            return term ? [
                {
                    kind: "run",
                    title: term,
                    subtitle: "Jalankan di shell"
                }
            ] : [];
        case "wall":
            {
                const out = [];
                const t = term.toLowerCase();
                for (let i = 0; i < walls.count; i++) {
                    const name = walls.get(i, "fileName");
                    if (!t || name.toLowerCase().includes(t))
                        out.push({
                            kind: "wall",
                            title: name,
                            subtitle: "Pasang wallpaper",
                            path: walls.get(i, "filePath")
                        });
                }
                return out.slice(0, 30);
            }
        default:
            return Apps.search(term, maxRows).map(a => ({
                        kind: "app",
                        title: a.name,
                        subtitle: a.comment || a.genericName || "",
                        icon: a.icon,
                        entry: a
                    }));
        }
    }

    function activate(i: int): void {
        const r = results[i];
        if (!r)
            return;
        switch (r.kind) {
        case "app":
            r.entry.execute();
            break;
        case "calc":
            Quickshell.execDetached(["wl-copy", r.title]);
            break;
        case "run":
            Quickshell.execDetached(["sh", "-c", r.title]);
            break;
        case "wall":
            Wallpaper.set(r.path);
            break;
        }
        DrawerState.close();
    }

    implicitWidth: 620
    implicitHeight: col.implicitHeight + Appearance.padding.large * 2

    onResultsChanged: list.currentIndex = 0
    onShownChanged: {
        if (shown) {
            input.text = DrawerState.launcherQuery;
            input.cursorPosition = input.text.length;
            DrawerState.launcherQuery = "";
            list.lastMouse = Qt.point(-1, -1);
            input.forceActiveFocus();
        }
    }

    FolderListModel {
        id: walls

        folder: `file://${Config.wallpaperDir}`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    Column {
        id: col

        x: Appearance.padding.large
        y: Appearance.padding.large
        width: root.width - Appearance.padding.large * 2
        spacing: Appearance.spacing.normal

        Item {
            width: parent.width
            height: list.count > 0 ? list.height : empty.height

            ListView {
                id: list

                // Posisi mouse terakhir (koordinat window); x < 0 = belum tercatat sejak dibuka
                property point lastMouse: Qt.point(-1, -1)

                width: parent.width
                height: Math.min(count, root.mode === "wall" ? 6 : root.maxRows) * root.rowHeight
                visible: count > 0
                clip: true
                model: root.results
                verticalLayoutDirection: ListView.BottomToTop
                highlightFollowsCurrentItem: false
                boundsBehavior: Flickable.StopAtBounds

                highlight: StyledRect {
                    width: list.width
                    height: root.rowHeight
                    y: list.currentItem?.y ?? 0
                    radius: Appearance.radius.normal
                    color: Appearance.colors.secondaryContainer

                    Behavior on y {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveFast
                        }
                    }
                }

                populate: Transition {
                    Anim {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Appearance.anim.durations.small
                    }
                }

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property color ink: current ? Appearance.colors.secondaryContainerText : Appearance.colors.text

                    width: ListView.view.width
                    height: root.rowHeight

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.padding.normal
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.spacing.large

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: row.modelData.kind === "wall" ? 80 : 36
                            height: row.modelData.kind === "wall" ? 48 : 36

                            IconImage {
                                anchors.centerIn: parent
                                visible: row.modelData.kind === "app"
                                implicitSize: 32
                                source: visible ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                                asynchronous: true
                            }

                            StyledClippingRect {
                                anchors.fill: parent
                                visible: row.modelData.kind === "wall"
                                radius: Appearance.radius.small

                                Image {
                                    anchors.fill: parent
                                    source: parent.visible ? `file://${row.modelData.path}` : ""
                                    sourceSize: Qt.size(160, 96)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                            }

                            StyledRect {
                                anchors.fill: parent
                                visible: row.modelData.kind === "calc" || row.modelData.kind === "run"
                                radius: Appearance.radius.small
                                color: Appearance.colors.tertiaryContainer

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: row.modelData.kind === "calc" ? "calculate" : "terminal"
                                    color: Appearance.colors.tertiaryContainerText
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: row.width - (row.modelData.kind === "wall" ? 80 : 36) - Appearance.spacing.large - Appearance.padding.normal * 2

                            StyledText {
                                width: parent.width
                                text: row.modelData.title
                                color: row.ink
                                font.pixelSize: row.modelData.kind === "calc" ? Appearance.font.size.large : Appearance.font.size.normal
                                font.family: row.modelData.kind === "calc" || row.modelData.kind === "run" ? Appearance.font.family.mono : Appearance.font.family.sans
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width
                                visible: text !== ""
                                text: row.modelData.subtitle
                                color: row.current ? Appearance.colors.secondaryContainerText : Appearance.colors.textDim
                                font.pixelSize: Appearance.font.size.small
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Pilih hanya kalau mouse benar-benar bergerak, bukan saat daftar bergeser di bawah kursor
                        onPositionChanged: mouse => {
                            const p = mapToItem(null, mouse.x, mouse.y);
                            const moved = list.lastMouse.x >= 0 && (p.x !== list.lastMouse.x || p.y !== list.lastMouse.y);
                            list.lastMouse = p;
                            if (moved)
                                list.currentIndex = row.index;
                        }
                        onClicked: root.activate(row.index)
                    }
                }
            }

            Column {
                id: empty

                anchors.horizontalCenter: parent.horizontalCenter
                visible: list.count === 0 && root.query !== ""
                height: visible ? implicitHeight : 0
                spacing: Appearance.spacing.small
                topPadding: Appearance.spacing.large
                bottomPadding: Appearance.spacing.large

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "search_off"
                    font.pixelSize: Appearance.font.size.extraLarge
                    color: Appearance.colors.textDim
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Tidak ada hasil"
                    color: Appearance.colors.textDim
                }
            }
        }

        StyledRect {
            width: parent.width
            height: 48
            radius: height / 2
            color: Appearance.colors.surfaceContainerHigh

            MaterialIcon {
                id: modeIcon

                anchors.left: parent.left
                anchors.leftMargin: Appearance.padding.normal + 2
                anchors.verticalCenter: parent.verticalCenter
                text: ({
                        apps: "search",
                        calc: "calculate",
                        run: "terminal",
                        wall: "wallpaper"
                    })[root.mode]
                color: Appearance.colors.primary
            }

            TextInput {
                id: input

                anchors.left: modeIcon.right
                anchors.leftMargin: Appearance.spacing.normal
                anchors.right: parent.right
                anchors.rightMargin: Appearance.padding.large
                anchors.verticalCenter: parent.verticalCenter
                color: Appearance.colors.text
                font.family: Appearance.font.family.sans
                font.pixelSize: Appearance.font.size.larger
                selectByMouse: true
                selectionColor: Appearance.colors.primary
                selectedTextColor: Appearance.colors.primaryText
                cursorDelegate: Rectangle {
                    width: 2
                    color: Appearance.colors.primary
                }

                Keys.onEscapePressed: DrawerState.close()
                Keys.onUpPressed: list.incrementCurrentIndex()
                Keys.onDownPressed: list.decrementCurrentIndex()
                Keys.onTabPressed: list.incrementCurrentIndex()
                Keys.onReturnPressed: root.activate(list.currentIndex)
                Keys.onEnterPressed: root.activate(list.currentIndex)

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: "Cari aplikasi     = hitung     > perintah     : wallpaper"
                    color: Appearance.colors.textDim
                }
            }
        }
    }
}
