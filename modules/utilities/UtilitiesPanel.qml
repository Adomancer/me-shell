import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.popouts

// Panel utilitas ala Caelestia: ubin toggle cepat, aksi tangkap layar, dan power profile.
ColumnLayout {
    id: root

    property bool shown: false
    // Lebar tetap; implicitWidth layout dihitung ulang oleh layout itu sendiri
    readonly property int pageWidth: 400

    // Ubin toggle: aktif = warna aksen
    component Tile: StyledRect {
        id: tile

        property string icon
        property string label
        property bool toggled: false
        readonly property color ink: toggled ? Appearance.colors.primaryText : Appearance.colors.text

        signal clicked

        Layout.fillWidth: true
        implicitHeight: 76
        radius: Appearance.radius.normal
        color: toggled ? Appearance.colors.primary : Appearance.colors.surfaceContainerHigh

        Column {
            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.icon
                fill: tile.toggled ? 1 : 0
                font.pixelSize: Appearance.font.size.extraLarge - 4
                color: tile.ink
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.label
                color: tile.ink
                font.pixelSize: Appearance.font.size.small
            }
        }

        StateLayer {
            color: tile.ink
            onClicked: tile.clicked()
        }
    }

    spacing: Appearance.spacing.normal

    onShownChanged: {
        if (shown)
            forceActiveFocus();
    }

    Keys.onEscapePressed: DrawerState.close()

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: "widgets"
            fill: 1
            color: Appearance.colors.primary
        }

        StyledText {
            Layout.fillWidth: true
            text: "Utilitas"
            font.family: Appearance.font.family.title
            font.pixelSize: Appearance.font.size.larger
            font.weight: Font.Medium
        }

        IconButton {
            icon: "content_paste"
            onClicked: DrawerState.toggleLauncher(";")
        }

        IconButton {
            icon: "settings"
            onClicked: DrawerState.open("settings")
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        rowSpacing: Appearance.spacing.small
        columnSpacing: Appearance.spacing.small

        Tile {
            icon: "coffee"
            label: "Kafein"
            toggled: Idle.inhibited
            onClicked: Idle.toggleInhibit()
        }

        Tile {
            icon: "sports_esports"
            label: "Game"
            toggled: GameMode.enabled
            onClicked: GameMode.toggle()
        }

        Tile {
            icon: "do_not_disturb_on"
            label: "Senyap"
            toggled: Notifs.dnd
            onClicked: Notifs.toggleDnd()
        }

        Tile {
            icon: "nightlight"
            label: "Malam"
            toggled: NightLight.enabled
            onClicked: NightLight.toggle()
        }

        Tile {
            icon: "screenshot_region"
            label: "Tangkap"
            onClicked: Screenshot.openPicker("screenshot")
        }

        Tile {
            icon: Recorder.recording ? "stop_circle" : "screen_record"
            label: Recorder.recording ? Recorder.elapsedText : "Rekam"
            toggled: Recorder.recording
            onClicked: Recorder.recording ? Recorder.stop() : Screenshot.openPicker("record")
        }

        Tile {
            icon: "colorize"
            label: "Warna"
            onClicked: Screenshot.pickColor()
        }

        Tile {
            icon: Audio.micMuted ? "mic_off" : "mic"
            label: "Mikrofon"
            toggled: !Audio.micMuted
            onClicked: Audio.toggleMic()
        }
    }

    ProfilePicker {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
    }
}
