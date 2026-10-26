import QtQuick
import qs.components
import qs.services
import qs.utils

// Ikon status tanpa kotak: jaringan, bluetooth, volume (+ angka), baterai (5 segmen + angka).
// Hover tiap ikon memunculkan popout-nya, klik menyematkan popout itu. Scroll mengubah volume.
Row {
    id: root

    readonly property string netIcon: {
        if (Network.ethernet)
            return "lan";
        if (!Network.wifiEnabled)
            return "signal_wifi_off";
        if (!Network.connected)
            return "signal_wifi_statusbar_not_connected";
        const s = Network.signal;
        return s > 75 ? "signal_wifi_4_bar" : s > 50 ? "network_wifi_3_bar" : s > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }
    readonly property string volIcon: Audio.muted ? "volume_off" : Audio.volume < 0.01 ? "volume_mute" : Audio.volume < 0.5 ? "volume_down" : "volume_up"

    component StatusIcon: StyledRect {
        id: item

        required property string popout
        default property alias content: inner.data
        readonly property bool open: DrawerState.popout === popout

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: inner.implicitWidth + Appearance.padding.small * 2 + 2
        implicitHeight: Config.barHeight - 10
        radius: height / 2

        Row {
            id: inner

            anchors.centerIn: parent
            spacing: 4
        }

        StateLayer {
            onClicked: Config.barPopouts ? trigger.pin() : DrawerState.togglePanel("dash")
            onWheel: event => Audio.setVolume(Math.max(0, Math.min(1, Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
        }

        PopoutTrigger {
            id: trigger

            popout: item.popout
        }

        ActiveDot {
            active: item.open && DrawerState.popoutPinned
        }
    }

    // Angka kecil di samping ikon
    component Value: StyledText {
        anchors.verticalCenter: parent.verticalCenter
        font.family: Appearance.font.family.mono
        font.pixelSize: Appearance.font.size.smaller
        color: Appearance.colors.textDim
    }

    spacing: 0

    // Indikator privasi: ada aplikasi yang sedang memakai mikrofon atau mengambil video
    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: Audio.micUsers.length > 0 || Audio.videoUsers.length > 0
        rightPadding: Appearance.spacing.small
        spacing: 2

        MaterialIcon {
            visible: Audio.micUsers.length > 0
            text: "mic"
            fill: 1
            color: Appearance.colors.primary
        }

        MaterialIcon {
            visible: Audio.videoUsers.length > 0
            text: "videocam"
            fill: 1
            color: Appearance.colors.primary
        }
    }

    StatusIcon {
        popout: "network"

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.netIcon
            color: Appearance.colors.text
        }

        // VPN aktif: gembok kecil di samping ikon jaringan
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Network.vpnActive
            text: "vpn_lock"
            font.pixelSize: Appearance.font.size.normal
            color: Appearance.colors.primary
        }
    }

    StatusIcon {
        visible: BluetoothService.available
        popout: "bluetooth"

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: BluetoothService.enabled ? (BluetoothService.devices.length > 0 ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
            color: Appearance.colors.text
        }
    }

    StatusIcon {
        popout: "audio"

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.volIcon
            color: Appearance.colors.text
        }

        Value {
            text: Audio.muted ? "--" : Math.round(Audio.volume * 100)
        }
    }

    StatusIcon {
        visible: Battery.available
        popout: "battery"

        // Baterai sebagai 5 segmen dalam bingkai tipis
        Item {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 24
            implicitHeight: 12

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: !Battery.charging && Battery.percentage < 0.15 ? Appearance.colors.error : Appearance.colors.outline
            }

            SegmentBar {
                anchors.fill: parent
                anchors.margins: 3
                segments: 5
                thickness: 2.5
                value: Battery.percentage
                onColor: !Battery.charging && Battery.percentage < 0.15 ? Appearance.colors.error : Appearance.colors.text
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: Battery.charging
                text: "bolt"
                fill: 1
                font.pixelSize: 12
                color: Appearance.colors.primary
            }
        }

        Value {
            text: Math.round(Battery.percentage * 100)
        }
    }
}
