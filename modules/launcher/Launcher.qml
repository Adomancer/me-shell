import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import qs.components
import qs.services
import qs.utils
import "../../utils/Calc.js" as Calc

// Launcher dengan mode prefix:
//   (kosong) aplikasi   = kalkulator   > perintah shell   : wallpaper
Reveal {
    id: root

    readonly property string query: input.text
    readonly property string mode: query.startsWith("=") ? "calc" : query.startsWith(">") ? "run" : query.startsWith(":") ? "wall" : "apps"
    readonly property string term: mode === "apps" ? query.trim() : query.slice(1).trim()
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
                    subtitle: "jalankan di shell"
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
                            subtitle: "pasang wallpaper",
                            path: walls.get(i, "filePath")
                        });
                }
                return out.slice(0, 30);
            }
        default:
            return Apps.search(term, Config.launcherMaxResults).map(a => ({
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

    edge: "center"
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

    RetroFrame {
        title: ({
                apps: "run",
                calc: "calc",
                run: "shell",
                wall: "wallpaper"
            })[root.mode]

        ColumnLayout {
            width: 560
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledText {
                    text: ">"
                    color: Appearance.colors.primary
                    font.pixelSize: Appearance.font.size.large
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: input.implicitHeight

                    TextInput {
                        id: input

                        anchors.fill: parent
                        color: Appearance.colors.text
                        font.family: Appearance.font.family.mono
                        font.pixelSize: Appearance.font.size.large
                        selectByMouse: true
                        selectionColor: Appearance.colors.primary
                        selectedTextColor: Appearance.colors.primaryText
                        cursorDelegate: Rectangle {
                            width: 9
                            color: Appearance.colors.primary
                        }

                        Keys.onEscapePressed: DrawerState.close()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onTabPressed: list.incrementCurrentIndex()
                        Keys.onReturnPressed: root.activate(list.currentIndex)
                        Keys.onEnterPressed: root.activate(list.currentIndex)
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: "cari aplikasi   = hitung   > perintah   : wallpaper"
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.border.thin
                color: Appearance.colors.outline
            }

            ListView {
                id: list

                // Posisi mouse terakhir (koordinat window); x < 0 = belum tercatat sejak dibuka
                property point lastMouse: Qt.point(-1, -1)

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 8 * 44)
                visible: count > 0
                clip: true
                model: root.results
                highlightMoveDuration: Appearance.anim.duration.fast
                highlight: Rectangle {
                    color: Appearance.colors.primary
                    radius: Appearance.radius.small
                }

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem

                    width: ListView.view.width
                    height: 44

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacing.normal
                        anchors.rightMargin: Appearance.spacing.normal
                        spacing: Appearance.spacing.large

                        Item {
                            implicitWidth: row.modelData.kind === "wall" ? 56 : 28
                            implicitHeight: 32

                            IconImage {
                                anchors.centerIn: parent
                                visible: row.modelData.kind === "app"
                                implicitSize: 28
                                source: visible ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                                asynchronous: true
                            }

                            Image {
                                anchors.fill: parent
                                visible: row.modelData.kind === "wall"
                                source: visible ? `file://${row.modelData.path}` : ""
                                sourceSize: Qt.size(112, 64)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: row.modelData.kind === "calc" || row.modelData.kind === "run"
                                text: row.modelData.kind === "calc" ? "=" : "$"
                                color: row.current ? Appearance.colors.primaryText : Appearance.colors.primary
                                font.pixelSize: Appearance.font.size.large
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: row.modelData.title
                                color: row.current ? Appearance.colors.primaryText : Appearance.colors.text
                                font.bold: row.current
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.subtitle
                                color: row.current ? Appearance.colors.primaryText : Appearance.colors.textDim
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

            StyledText {
                visible: list.count === 0 && root.query !== ""
                text: "-- tidak ada hasil --"
                color: Appearance.colors.textDim
            }
        }
    }
}
