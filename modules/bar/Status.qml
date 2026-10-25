import QtQuick
import qs.components
import qs.services
import qs.utils

// Ikon status: jaringan, bluetooth, volume, baterai. Klik membuka dashboard, scroll mengubah volume.
StyledRect {
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
    readonly property string batIcon: {
        if (Battery.charging)
            return "battery_charging_full";
        const p = Battery.percentage;
        return p > 0.95 ? "battery_full" : `battery_${Math.max(0, Math.min(6, Math.floor(p * 7)))}_bar`;
    }

    implicitWidth: row.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: Config.barHeight - 10
    radius: height / 2
    color: Appearance.colors.surfaceContainer

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.netIcon
            color: Appearance.colors.text
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: BluetoothService.available
            text: BluetoothService.enabled ? "bluetooth" : "bluetooth_disabled"
            color: Appearance.colors.text
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.volIcon
            color: Appearance.colors.text
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.available
            spacing: 2

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batIcon
                rotation: 90
                color: !Battery.charging && Battery.percentage < 0.15 ? Appearance.colors.error : Appearance.colors.text
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round(Battery.percentage * 100)}%`
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.smaller
            }
        }
    }

    StateLayer {
        onClicked: DrawerState.togglePanel("dash")
        onWheel: event => Audio.setVolume(Math.max(0, Math.min(1, Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
