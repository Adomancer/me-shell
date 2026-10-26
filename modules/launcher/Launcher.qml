import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import Qt.labs.folderlistmodel
import qs.components
import qs.services
import qs.utils
import "../../utils/Calc.js" as Calc
import "../../utils/Fuzzy.js" as Fuzzy

// Launcher yang muncul dari tepi bawah, dengan mode prefix:
//   (kosong) aplikasi   / aksi shell   ; clipboard   . emoji   : wallpaper   = kalkulator   > perintah shell
// Mode wallpaper memakai carousel mendatar; launcher melebar mengikutinya.
Item {
    id: root

    property bool shown: false

    readonly property string query: input.text
    readonly property string mode: ({
            "=": "calc",
            ">": "run",
            ":": "wall",
            "/": "action",
            ";": "clip",
            ".": "emoji"
        })[query.charAt(0)] ?? "apps"
    readonly property string term: mode === "apps" ? query.trim() : query.slice(1).trim()
    readonly property bool carousel: mode === "wall"
    readonly property bool showEmpty: results.length === 0 && query !== ""
    // [[emoji, nama]] dari assets/emoji.txt, dimuat sekali
    property var emojis: []
    readonly property int rowHeight: 56
    readonly property int maxRows: Config.launcherMaxResults

    // Aksi untuk mode "/". run dipanggil setelah launcher tertutup; keep = launcher tetap terbuka.
    readonly property var actions: [
        {
            icon: "screenshot_region",
            title: "Screenshot area",
            subtitle: "Klik window atau seret area",
            run: () => Screenshot.openPicker("screenshot")
        },
        {
            icon: "screenshot_monitor",
            title: "Screenshot layar penuh",
            run: () => Screenshot.full()
        },
        {
            icon: "screen_record",
            title: Recorder.recording ? "Hentikan rekaman" : "Rekam layar",
            run: () => Recorder.recording ? Recorder.stop() : Screenshot.openPicker("record")
        },
        {
            icon: "colorize",
            title: "Ambil warna dari layar",
            run: () => Screenshot.pickColor()
        },
        {
            icon: "coffee",
            title: Idle.inhibited ? "Matikan kafein" : "Kafein (tahan layar menyala)",
            run: () => Idle.toggleInhibit()
        },
        {
            icon: "sports_esports",
            title: GameMode.enabled ? "Matikan mode game" : "Mode game",
            run: () => GameMode.toggle()
        },
        {
            icon: "nightlight",
            title: NightLight.enabled ? "Matikan lampu malam" : "Lampu malam",
            run: () => NightLight.toggle()
        },
        {
            icon: "do_not_disturb_on",
            title: Notifs.dnd ? "Matikan jangan ganggu" : "Jangan ganggu",
            run: () => Notifs.toggleDnd()
        },
        {
            icon: Config.colorMode === "dark" ? "light_mode" : "dark_mode",
            title: Config.colorMode === "dark" ? "Tema terang" : "Tema gelap",
            run: () => {
                Config.set("colorMode", Config.colorMode === "dark" ? "light" : "dark");
                if (Wallpaper.current)
                    Wallpaper.set(Wallpaper.current);
            }
        },
        {
            icon: "shuffle",
            title: "Wallpaper acak",
            run: () => {
                if (walls.count > 0)
                    Wallpaper.set(walls.get(Math.floor(Math.random() * walls.count), "filePath"));
            }
        },
        {
            icon: "wallpaper",
            title: "Pilih wallpaper",
            keep: true,
            run: () => root.setQuery(":")
        },
        {
            icon: "content_paste",
            title: "Riwayat clipboard",
            keep: true,
            run: () => root.setQuery(";")
        },
        {
            icon: "grid_view",
            title: "Overview workspace",
            run: () => DrawerState.open("overview")
        },
        {
            icon: "widgets",
            title: "Utilitas",
            run: () => DrawerState.open("utilities")
        },
        {
            icon: "settings",
            title: "Pengaturan",
            run: () => DrawerState.open("settings")
        },
        {
            icon: "lock",
            title: "Kunci layar",
            run: () => Session.lock()
        },
        {
            icon: "bedtime",
            title: "Tidur",
            run: () => Session.suspend()
        },
        {
            icon: "restart_alt",
            title: "Restart",
            run: () => Session.reboot()
        },
        {
            icon: "power_settings_new",
            title: "Matikan",
            run: () => Session.poweroff()
        },
        {
            icon: "logout",
            title: "Keluar dari Hyprland",
            run: () => Session.logout()
        }
    ]

    readonly property var results: {
        switch (mode) {
        case "calc":
            {
                const r = Calc.evaluate(term);
                return r === null ? [] : [
                    {
                        kind: "calc",
                        icon: "calculate",
                        title: String(r),
                        subtitle: "Enter untuk menyalin"
                    }
                ];
            }
        case "run":
            return term ? [
                {
                    kind: "run",
                    icon: "terminal",
                    title: term,
                    subtitle: "Jalankan di shell"
                }
            ] : [];
        case "action":
            {
                // sort V4 tidak stabil, jadi tanpa kata kunci urutan asli dipakai apa adanya
                const scored = actions.map(a => ({
                            a,
                            s: Fuzzy.score(term, a.title)
                        })).filter(r => r.s > 0);
                return (term ? scored.sort((x, y) => y.s - x.s) : scored).slice(0, maxRows).map(r => Object.assign({
                        kind: "action",
                        subtitle: ""
                    }, r.a));
            }
        case "clip":
            {
                const t = term.toLowerCase();
                return Clipboard.entries.filter(e => !t || e.text.toLowerCase().includes(t)).slice(0, 50).map(e => {
                    const img = e.text.match(/binary data .*? (\w+) (\d+x\d+)/);
                    return {
                        kind: "clip",
                        icon: e.image ? "image" : "content_paste",
                        title: img ? `Gambar ${img[1].toUpperCase()} ${img[2].replace("x", " × ")}` : e.text.replace(/\s+/g, " ").trim(),
                        subtitle: e.image ? "Enter untuk menyalin lagi" : "",
                        line: e.line
                    };
                });
            }
        case "emoji":
            {
                const words = term.toLowerCase().split(/\s+/).filter(w => w);
                return emojis.filter(e => words.every(w => e[1].includes(w))).slice(0, maxRows).map(e => ({
                            kind: "emoji",
                            glyph: e[0],
                            title: e[1],
                            subtitle: ""
                        }));
            }
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
                            path: walls.get(i, "filePath")
                        });
                }
                return out.slice(0, 100);
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

    function currentIndex(): int {
        return carousel ? wallView.currentIndex : list.currentIndex;
    }

    function setQuery(q: string): void {
        input.text = q;
        input.cursorPosition = q.length;
    }

    function activate(i: int): void {
        const r = results[i];
        if (!r)
            return;
        if (r.kind === "action") {
            if (r.keep) {
                r.run();
                return;
            }
            DrawerState.close();
            r.run();
            return;
        }
        switch (r.kind) {
        case "app":
            Apps.launch(r.entry);
            break;
        case "calc":
            Quickshell.execDetached(["wl-copy", r.title]);
            break;
        case "run":
            Quickshell.execDetached(["sh", "-c", r.title]);
            break;
        case "clip":
            Clipboard.copy(r.line);
            break;
        case "emoji":
            Quickshell.execDetached(["wl-copy", r.glyph]);
            Toaster.show("mood", "Emoji disalin", `${r.glyph}  ${r.title}`, "");
            break;
        case "wall":
            Wallpaper.set(r.path);
            break;
        }
        DrawerState.close();
    }

    implicitWidth: carousel ? 940 : 620
    implicitHeight: col.implicitHeight + Appearance.padding.large * 2

    onResultsChanged: {
        list.currentIndex = 0;
        // Wallpaper aktif jadi pilihan awal carousel (setelah model carousel ikut berganti)
        if (carousel)
            Qt.callLater(() => wallView.currentIndex = Math.max(0, results.findIndex(r => r.path === Wallpaper.current)));
    }
    onModeChanged: {
        if (mode === "clip")
            Clipboard.refresh();
    }
    onShownChanged: {
        if (shown) {
            setQuery(DrawerState.launcherQuery);
            DrawerState.launcherQuery = "";
            list.lastMouse = Qt.point(-1, -1);
            input.forceActiveFocus();
        }
    }

    FileView {
        path: `${Paths.shell}/assets/emoji.txt`
        onLoaded: root.emojis = text().split("\n").filter(l => l.includes("\t")).map(l => l.split("\t"))
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

        // Carousel wallpaper: yang di tengah membesar, sisanya mengecil dan meredup
        ListView {
            id: wallView

            readonly property int itemWidth: 300

            width: parent.width
            height: root.carousel && count > 0 ? 230 : 0
            visible: height > 0
            orientation: ListView.Horizontal
            clip: true
            spacing: Appearance.spacing.normal
            model: root.carousel ? root.results : []
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (width - itemWidth) / 2
            preferredHighlightEnd: (width + itemWidth) / 2
            highlightMoveDuration: Appearance.anim.durations.normal
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: wall

                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                readonly property bool active: modelData.path === Wallpaper.current

                width: wallView.itemWidth
                height: wallView.height

                StyledClippingRect {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (parent.height - 30 - height) / 2
                    width: parent.width * (wall.current ? 1 : 0.84)
                    height: (parent.height - 30) * (wall.current ? 1 : 0.84)
                    radius: wall.current ? Appearance.radius.large : Appearance.radius.normal
                    color: Appearance.colors.surfaceContainerHigh
                    opacity: wall.current ? 1 : 0.6

                    Behavior on width {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                        }
                    }
                    Behavior on height {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                        }
                    }
                    Behavior on opacity {
                        Anim {}
                    }

                    Image {
                        anchors.fill: parent
                        source: wall.modelData.path ? `file://${wall.modelData.path}` : ""
                        sourceSize: Qt.size(600, 400)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // Penanda wallpaper yang sedang dipakai
                    StyledRect {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Appearance.padding.small
                        visible: wall.active
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: Appearance.radius.small
                        color: Appearance.colors.primary

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "check"
                            font.pixelSize: Appearance.font.size.larger
                            color: Appearance.colors.primaryText
                        }
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: wall.modelData.title
                    color: wall.current ? Appearance.colors.text : Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                    elide: Text.ElideMiddle
                    opacity: wall.current ? 1 : 0

                    Behavior on opacity {
                        Anim {}
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wall.current ? root.activate(wall.index) : wallView.currentIndex = wall.index
                }
            }
        }

        Item {
            width: parent.width
            height: root.showEmpty ? empty.implicitHeight : root.carousel ? 0 : list.height
            visible: height > 0

            ListView {
                id: list

                // Posisi mouse terakhir (koordinat window); x < 0 = belum tercatat sejak dibuka
                property point lastMouse: Qt.point(-1, -1)

                width: parent.width
                height: Math.min(count, root.maxRows) * root.rowHeight
                visible: count > 0
                clip: true
                model: root.carousel ? [] : root.results
                verticalLayoutDirection: ListView.BottomToTop
                highlightFollowsCurrentItem: false
                boundsBehavior: Flickable.StopAtBounds

                // Sorotan: fill tipis + batang aksen di kiri, meluncur dengan pegas
                highlight: StyledRect {
                    width: list.width
                    height: root.rowHeight
                    y: list.currentItem?.y ?? 0
                    radius: Appearance.radius.normal
                    color: Appearance.colors.surfaceContainerHigh

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: parent.height * 0.5
                        radius: 1.5
                        color: Appearance.colors.primary
                    }

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
                    readonly property color ink: current ? Appearance.colors.primary : Appearance.colors.text
                    readonly property bool mono: modelData.kind === "calc" || modelData.kind === "run"

                    width: ListView.view.width
                    height: root.rowHeight

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.padding.normal
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.spacing.large

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            height: 36

                            IconImage {
                                anchors.centerIn: parent
                                visible: row.modelData.kind === "app"
                                implicitSize: 32
                                // iconPath(nama, fallback) dengan nama kosong menghasilkan path rusak
                                source: visible ? Quickshell.iconPath(row.modelData.icon || "application-x-executable", "application-x-executable") : ""
                                asynchronous: true
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: row.modelData.kind === "emoji"
                                text: row.modelData.glyph ?? ""
                                font.pixelSize: 26
                            }

                            StyledRect {
                                anchors.fill: parent
                                visible: row.modelData.kind !== "app" && row.modelData.kind !== "emoji"
                                radius: Appearance.radius.small
                                color: row.modelData.kind === "action" ? Appearance.colors.primaryContainer : Appearance.colors.tertiaryContainer

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: row.modelData.icon ?? ""
                                    color: row.modelData.kind === "action" ? Appearance.colors.primaryContainerText : Appearance.colors.tertiaryContainerText
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: row.width - 36 - Appearance.spacing.large - Appearance.padding.normal * 2

                            StyledText {
                                width: parent.width
                                text: row.modelData.title
                                color: row.ink
                                font.pixelSize: row.modelData.kind === "calc" ? Appearance.font.size.large : Appearance.font.size.normal
                                font.family: row.mono ? Appearance.font.family.mono : Appearance.font.family.sans
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            StyledText {
                                width: parent.width
                                visible: text !== ""
                                text: row.modelData.subtitle ?? ""
                                color: Appearance.colors.textDim
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
                visible: root.showEmpty
                spacing: Appearance.spacing.small
                topPadding: Appearance.spacing.large
                bottomPadding: Appearance.spacing.large

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.mode === "clip" ? "content_paste_off" : "search_off"
                    font.pixelSize: Appearance.font.size.extraLarge
                    color: Appearance.colors.textDim
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.mode === "clip" && !Clipboard.available ? "Install cliphist untuk riwayat clipboard" : root.mode === "clip" ? "Clipboard masih kosong" : "Tidak ada hasil"
                    color: Appearance.colors.textDim
                }
            }
        }

        // Kolom cari tanpa kotak: hanya garis bawah
        Item {
            width: parent.width
            height: 48

            Divider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }

            MaterialIcon {
                id: modeIcon

                anchors.left: parent.left
                anchors.leftMargin: Appearance.padding.normal + 2
                anchors.verticalCenter: parent.verticalCenter
                text: ({
                        apps: "search",
                        calc: "calculate",
                        run: "terminal",
                        wall: "wallpaper",
                        action: "bolt",
                        clip: "content_paste",
                        emoji: "mood"
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
                // Kursor blok berkedip ala terminal lama
                cursorDelegate: Rectangle {
                    width: 9
                    color: Appearance.colors.primary

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: true

                        PropertyAction {
                            value: 1
                        }
                        PauseAnimation {
                            duration: 530
                        }
                        PropertyAction {
                            value: 0
                        }
                        PauseAnimation {
                            duration: 530
                        }
                    }
                }

                Keys.onEscapePressed: DrawerState.close()
                Keys.onUpPressed: list.incrementCurrentIndex()
                Keys.onDownPressed: list.decrementCurrentIndex()
                Keys.onTabPressed: root.carousel ? wallView.incrementCurrentIndex() : list.incrementCurrentIndex()
                Keys.onReturnPressed: root.activate(root.currentIndex())
                Keys.onEnterPressed: root.activate(root.currentIndex())
                Keys.onPressed: event => {
                    // Panah kiri/kanan menggeser carousel, bukan kursor teks
                    if (root.carousel && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                        event.key === Qt.Key_Left ? wallView.decrementCurrentIndex() : wallView.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (root.mode === "clip" && event.key === Qt.Key_Delete) {
                        const r = root.results[list.currentIndex];
                        if (r)
                            Clipboard.remove(r.line);
                        event.accepted = true;
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: "Cari aplikasi   / aksi   ; clipboard   . emoji   : wallpaper   = hitung   > perintah"
                    color: Appearance.colors.textDim
                }
            }
        }
    }
}
