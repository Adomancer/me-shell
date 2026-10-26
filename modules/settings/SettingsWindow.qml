import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Menu settings: jendela mengambang di tengah dengan sidebar kategori (ala end_4).
// Semua perubahan langsung disimpan ke config.json; keybind perlu "Terapkan".
Item {
    id: root

    property bool shown: false
    property string page: "general"
    readonly property var pages: [
        {
            id: "general",
            label: "Umum",
            desc: "Jam, workspace, dan launcher",
            icon: "tune"
        },
        {
            id: "look",
            label: "Tampilan",
            desc: "Tema, font, bingkai, dan animasi",
            icon: "palette"
        },
        {
            id: "bar",
            label: "Bar",
            desc: "Isi dan ukuran bar atas",
            icon: "toolbar"
        },
        {
            id: "desktop",
            label: "Desktop",
            desc: "Widget di atas wallpaper",
            icon: "desktop_windows"
        },
        {
            id: "wallpaper",
            label: "Wallpaper",
            desc: "Wallpaper dan warna yang ikut wallpaper",
            icon: "wallpaper"
        },
        {
            id: "keys",
            label: "Keybind",
            desc: "Klik Ubah lalu tekan kombinasi baru. Esc untuk batal",
            icon: "keyboard"
        },
        {
            id: "system",
            label: "Sistem",
            desc: "Idle, lampu malam, tangkap layar, dan clipboard",
            icon: "settings_power"
        },
        {
            id: "services",
            label: "Layanan",
            desc: "Cuaca, notifikasi, audio, dan jaringan",
            icon: "widgets"
        },
        {
            id: "about",
            label: "Tentang",
            desc: "",
            icon: "info"
        }
    ]
    readonly property int index: Math.max(0, pages.findIndex(p => p.id === page))
    readonly property var current: pages[index]
    property real progress: shown ? 1 : 0

    function open(id: string): void {
        if (id === page)
            return;
        page = id;
        flick.contentY = 0;
        enter.restart();
    }

    implicitWidth: 960
    implicitHeight: 600
    // Ukuran 0 saat tertutup supaya keluar dari mask input
    width: progress > 0 ? implicitWidth : 0
    height: progress > 0 ? implicitHeight : 0
    visible: progress > 0
    opacity: progress
    scale: 0.9 + progress * 0.1

    onShownChanged: {
        if (shown)
            body.forceActiveFocus();
    }

    Behavior on progress {
        Anim {
            duration: root.shown ? Appearance.anim.durations.expressiveDefault : Appearance.anim.durations.small
            easing.bezierCurve: root.shown ? Appearance.anim.curves.expressiveDefault : Appearance.anim.curves.emphasizedAccel
        }
    }

    // Halaman baru masuk: muncul dari sedikit bawah
    ParallelAnimation {
        id: enter

        Anim {
            target: content
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.anim.durations.normal
        }
        Anim {
            target: shift
            property: "y"
            from: 24
            to: 0
            duration: Appearance.anim.durations.normal
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Component {
        id: generalPage

        GeneralPage {}
    }

    Component {
        id: lookPage

        AppearancePage {}
    }

    Component {
        id: barPage

        BarPage {}
    }

    Component {
        id: desktopPage

        DesktopPage {}
    }

    Component {
        id: systemPage

        SystemPage {}
    }

    Component {
        id: wallpaperPage

        WallpaperPage {}
    }

    Component {
        id: keysPage

        KeybindPage {}
    }

    Component {
        id: servicesPage

        ServicesPage {}
    }

    Component {
        id: aboutPage

        AboutPage {}
    }

    Elevation {
        anchors.fill: bg
        radius: bg.radius
        level: 3
    }

    StyledRect {
        id: bg

        anchors.fill: parent
        radius: Appearance.radius.large
        color: Appearance.colors.surface
    }

    RowLayout {
        id: body

        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: Appearance.spacing.normal
        focus: true
        Keys.onEscapePressed: DrawerState.close()
        Keys.onUpPressed: root.open(root.pages[Math.max(0, root.index - 1)].id)
        Keys.onDownPressed: root.open(root.pages[Math.min(root.pages.length - 1, root.index + 1)].id)

        // Sidebar kategori
        Item {
            Layout.preferredWidth: 220
            Layout.fillHeight: true

            Column {
                id: nav

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: Appearance.padding.small
                spacing: 2

                Row {
                    id: navHeader

                    leftPadding: Appearance.padding.normal
                    bottomPadding: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    Caption {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Pengaturan"
                        color: Appearance.colors.text
                    }
                }

                Repeater {
                    model: root.pages

                    Item {
                        id: item

                        required property var modelData
                        required property int index
                        readonly property bool isActive: root.page === modelData.id

                        width: nav.width
                        height: 48

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Appearance.padding.normal + 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Appearance.spacing.normal

                            // Nomor ala TE + label
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(item.index + 1).padStart(2, "0")
                                color: item.isActive ? Appearance.colors.primary : Appearance.colors.outline
                                font.family: Appearance.font.family.mono
                                font.pixelSize: Appearance.font.size.small
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: item.modelData.label
                                color: item.isActive ? Appearance.colors.text : Appearance.colors.textDim
                                font.weight: item.isActive ? Font.Medium : Font.Normal
                            }
                        }

                        StateLayer {
                            radius: height / 2
                            onClicked: root.open(item.modelData.id)
                        }
                    }
                }
            }

            // Sorotan halaman aktif: titik aksen yang meluncur dengan pegas
            StyledRect {
                z: -1
                x: nav.x + 4
                y: nav.y + navHeader.height + nav.spacing + root.index * (48 + nav.spacing) + (48 - height) / 2
                width: 6
                height: 6
                radius: 3
                color: Appearance.colors.primary

                Behavior on y {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
                }
            }

            StyledText {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: Appearance.padding.normal
                text: "me-shell 0.1.0"
                color: Appearance.colors.textDim
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.small
            }
        }

        Divider {
            vertical: true
        }

        // Isi halaman: tanpa kotak sendiri, satu permukaan dengan sidebar
        StyledClippingRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.radius.large
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Flickable {
                    id: flick

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: content.implicitHeight + Appearance.spacing.huge * 2

                    ColumnLayout {
                        id: content

                        x: Appearance.spacing.huge
                        y: Appearance.spacing.huge
                        width: flick.width - Appearance.spacing.huge * 2
                        spacing: 2

                        transform: Translate {
                            id: shift
                        }

                        // Nomor halaman dot-matrix + judul
                        Row {
                            visible: root.current.id !== "about"
                            spacing: Appearance.spacing.large

                            DisplayText {
                                anchors.baseline: pageTitle.baseline
                                text: String(root.index + 1).padStart(2, "0")
                                weight: 800
                                color: Appearance.colors.primary
                                font.pixelSize: 40
                            }

                            StyledText {
                                id: pageTitle

                                text: root.current.label
                                font.pixelSize: Appearance.font.size.extraLarge
                                font.weight: Font.Medium
                            }
                        }

                        StyledText {
                            visible: root.current.desc !== ""
                            Layout.bottomMargin: Appearance.spacing.normal
                            text: root.current.desc
                            color: Appearance.colors.textDim
                        }

                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: ({
                                    general: generalPage,
                                    look: lookPage,
                                    bar: barPage,
                                    desktop: desktopPage,
                                    wallpaper: wallpaperPage,
                                    system: systemPage,
                                    keys: keysPage,
                                    services: servicesPage,
                                    about: aboutPage
                                })[root.page]
                        }
                    }

                    // Isi masih berlanjut di bawah: memudar ke warna latar
                    Rectangle {
                        parent: flick
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 40
                        opacity: flick.contentY < flick.contentHeight - flick.height - 1 ? 1 : 0
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "transparent"
                            }
                            GradientStop {
                                position: 1
                                color: Appearance.colors.surface
                            }
                        }

                        Behavior on opacity {
                            Anim {
                                duration: Appearance.anim.durations.small
                            }
                        }
                    }
                }

                Divider {
                    Layout.leftMargin: Appearance.spacing.huge
                    Layout.rightMargin: Appearance.spacing.huge
                }

                // Status simpan
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.normal
                    Layout.leftMargin: Appearance.spacing.huge
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: Keybinds.dirty ? "pending" : "cloud_done"
                        fill: 1
                        color: Keybinds.dirty ? Appearance.colors.error : Appearance.colors.primary
                        font.pixelSize: Appearance.font.size.larger
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Keybinds.dirty ? "Keybind berubah, belum diterapkan" : `Tersimpan otomatis di ${Paths.config}/config.json`
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.smaller
                        elide: Text.ElideMiddle
                    }

                    TextButton {
                        visible: root.page === "keys" || Keybinds.dirty
                        disabled: !Keybinds.dirty
                        type: "filled"
                        icon: "check"
                        text: "Terapkan keybind"
                        onClicked: Keybinds.apply()
                    }
                }
            }
        }
    }
}
