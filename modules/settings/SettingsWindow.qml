import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import "../../utils/PixelIcons.js" as Icons

// Menu settings: jendela retro di tengah dengan sidebar kategori (ala end_4).
// Semua perubahan langsung disimpan ke config.json; keybind perlu TERAPKAN.
Reveal {
    id: root

    property string page: "general"
    property real progress: 1
    readonly property real stepped: Math.round(progress * 5) / 5
    readonly property var pages: [
        {
            id: "general",
            label: "UMUM",
            desc: "Jam, workspace, dan launcher.",
            icon: Icons.setGeneral
        },
        {
            id: "look",
            label: "TAMPILAN",
            desc: "Tema, font, dan efek retro.",
            icon: Icons.setLook
        },
        {
            id: "bar",
            label: "BAR",
            desc: "Isi dan ukuran bar atas.",
            icon: Icons.setBar
        },
        {
            id: "wallpaper",
            label: "WALLPAPER",
            desc: "Wallpaper dan warna yang ikut wallpaper.",
            icon: Icons.setWallpaper
        },
        {
            id: "keys",
            label: "KEYBIND",
            desc: "Klik UBAH lalu tekan kombinasi baru. Esc untuk batal.",
            icon: Icons.setKeys
        },
        {
            id: "services",
            label: "LAYANAN",
            desc: "Cuaca, notifikasi, audio, dan jaringan.",
            icon: Icons.setServices
        },
        {
            id: "about",
            label: "TENTANG",
            desc: "",
            icon: Icons.setAbout
        }
    ]
    readonly property var current: pages.find(p => p.id === page) ?? pages[0]

    function open(id: string): void {
        if (id === page)
            return;
        page = id;
        flick.contentY = 0;
        enter.restart();
    }

    edge: "center"
    onShownChanged: {
        if (shown)
            frame.forceActiveFocus();
    }

    SequentialAnimation {
        id: enter

        PropertyAction {
            target: root
            property: "progress"
            value: 0
        }
        NumberAnimation {
            target: root
            property: "progress"
            to: 1
            duration: 260
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

    RetroFrame {
        id: frame

        title: "settings // me-shell"
        focus: true
        Keys.onEscapePressed: DrawerState.close()
        Keys.onUpPressed: root.open(root.pages[Math.max(0, root.pages.indexOf(root.current) - 1)].id)
        Keys.onDownPressed: root.open(root.pages[Math.min(root.pages.length - 1, root.pages.indexOf(root.current) + 1)].id)

        RowLayout {
            width: 900
            height: 540
            spacing: 0

            // Sidebar kategori
            ColumnLayout {
                Layout.preferredWidth: 184
                Layout.fillHeight: true
                Layout.rightMargin: Appearance.spacing.normal
                spacing: Appearance.spacing.small

                Repeater {
                    model: root.pages

                    StyledRect {
                        id: item

                        required property var modelData
                        readonly property bool isActive: root.page === modelData.id
                        readonly property color ink: isActive ? Appearance.colors.onPrimary : mouse.containsMouse ? Appearance.colors.text : Appearance.colors.textDim

                        Layout.fillWidth: true
                        implicitHeight: 40
                        color: isActive ? Appearance.colors.primary : mouse.containsMouse ? Appearance.colors.surfaceHigh : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Appearance.spacing.normal
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Appearance.spacing.normal

                            PixelIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                rows: item.modelData.icon
                                pixel: 2
                                color: item.ink
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: item.modelData.label
                                color: item.ink
                                font.bold: true
                                font.letterSpacing: 2
                            }
                        }

                        MouseArea {
                            id: mouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.open(item.modelData.id)
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                StyledText {
                    Layout.leftMargin: Appearance.spacing.normal
                    text: "me-shell 0.1.0"
                    color: Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: Appearance.border.normal
                color: Appearance.colors.outline
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Flickable {
                    id: flick

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: content.implicitHeight + Appearance.spacing.huge

                    ColumnLayout {
                        id: content

                        x: Appearance.spacing.huge
                        y: Appearance.spacing.normal
                        width: flick.width - Appearance.spacing.huge * 2
                        spacing: 2
                        opacity: root.stepped

                        transform: Translate {
                            x: (1 - root.stepped) * -24
                        }

                        StyledText {
                            visible: root.current.id !== "about"
                            text: root.current.label
                            color: Appearance.colors.primary
                            font.pixelSize: 20
                            font.bold: true
                            font.letterSpacing: 3
                        }

                        StyledText {
                            visible: root.current.desc !== ""
                            Layout.bottomMargin: Appearance.spacing.normal
                            text: root.current.desc
                            color: Appearance.colors.textDim
                            font.pixelSize: Appearance.font.size.small
                        }

                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: ({
                                    general: generalPage,
                                    look: lookPage,
                                    bar: barPage,
                                    wallpaper: wallpaperPage,
                                    keys: keysPage,
                                    services: servicesPage,
                                    about: aboutPage
                                })[root.page]
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Appearance.border.normal
                    color: Appearance.colors.outline
                }

                // Status simpan
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Appearance.spacing.normal
                    Layout.leftMargin: Appearance.spacing.huge
                    spacing: Appearance.spacing.large

                    Rectangle {
                        implicitWidth: 8
                        implicitHeight: 8
                        color: Keybinds.dirty ? Appearance.colors.error : Appearance.colors.primary
                        opacity: Keybinds.dirty && !blink.lit ? 0 : 1

                        Timer {
                            id: blink

                            property bool lit: true

                            interval: 250
                            repeat: true
                            running: Keybinds.dirty && root.shown
                            onTriggered: lit = !lit
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Keybinds.dirty ? "KEYBIND BERUBAH · BELUM DITERAPKAN" : `TERSIMPAN · ${Paths.config}/config.json`
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                        elide: Text.ElideMiddle
                    }

                    RetroButton {
                        visible: root.page === "keys" || Keybinds.dirty
                        enabled: Keybinds.dirty
                        active: Keybinds.dirty
                        text: "TERAPKAN KEYBIND"
                        onClicked: Keybinds.apply()
                    }
                }
            }
        }
    }
}
