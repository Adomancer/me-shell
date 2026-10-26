import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Daftar Wi-Fi: klik untuk menyambung/memutus. Jaringan baru yang berpassword membuka kolom password.
// Di bawahnya profil VPN/WireGuard kalau ada.
ColumnLayout {
    id: root

    readonly property int pageWidth: 320

    function signalIcon(s: int): string {
        return s > 75 ? "signal_wifi_4_bar" : s > 50 ? "network_wifi_3_bar" : s > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    spacing: 2

    Component.onCompleted: Network.scan()

    PopoutHeader {
        icon: "wifi"
        title: "Wi-Fi"
        hasSwitch: true
        checked: Network.wifiEnabled
        onToggled: v => {
            Network.setWifi(v);
            if (v)
                rescan.restart();
        }
    }

    ListRow {
        visible: Network.ethernet
        icon: "lan"
        title: "Ethernet"
        subtitle: "Tersambung"
        active: true
    }

    Repeater {
        model: Network.wifiEnabled ? Network.networks.slice(0, 8) : []

        ColumnLayout {
            id: net

            required property var modelData
            readonly property bool askPassword: Network.needsPassword === modelData.ssid

            Layout.fillWidth: true
            spacing: 2

            ListRow {
                icon: root.signalIcon(net.modelData.signal)
                title: net.modelData.ssid
                subtitle: net.modelData.active ? "Tersambung" : net.modelData.known ? "Tersimpan" : ""
                trailing: net.modelData.secure ? "lock" : ""
                active: net.modelData.active
                busy: Network.connecting === net.modelData.ssid
                onClicked: {
                    if (net.modelData.active)
                        Network.disconnect(net.modelData.ssid);
                    else if (net.modelData.secure && !net.modelData.known)
                        Network.needsPassword = net.modelData.ssid;
                    else
                        Network.connect(net.modelData.ssid, "");
                }
            }

            // Kolom password: popout disematkan supaya keyboard masuk ke sini
            StyledRect {
                Layout.fillWidth: true
                Layout.bottomMargin: Appearance.spacing.small
                visible: net.askPassword
                implicitHeight: 40
                radius: Appearance.radius.small
                color: Appearance.colors.surfaceContainerHigh

                onVisibleChanged: {
                    if (visible) {
                        DrawerState.pinPopout("network", DrawerState.popoutX, DrawerState.popoutScreen);
                        password.text = "";
                        password.forceActiveFocus();
                    }
                }

                MaterialIcon {
                    id: keyIcon

                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.padding.normal
                    anchors.verticalCenter: parent.verticalCenter
                    text: "key"
                    color: Appearance.colors.primary
                }

                TextInput {
                    id: password

                    anchors.left: keyIcon.right
                    anchors.leftMargin: Appearance.spacing.small
                    anchors.right: go.left
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    color: Appearance.colors.text
                    font.family: Appearance.font.family.sans
                    font.pixelSize: Appearance.font.size.normal
                    clip: true
                    Keys.onReturnPressed: Network.connect(net.modelData.ssid, text)
                    Keys.onEnterPressed: Network.connect(net.modelData.ssid, text)
                    Keys.onEscapePressed: Network.needsPassword = ""

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: password.text === ""
                        text: "Password"
                        color: Appearance.colors.textDim
                    }
                }

                IconButton {
                    id: go

                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "arrow_forward"
                    type: "filled"
                    toggled: true
                    size: Appearance.font.size.larger
                    onClicked: Network.connect(net.modelData.ssid, password.text)
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
        visible: !Network.wifiEnabled || (Network.networks.length === 0 && !Network.scanning)
        horizontalAlignment: Text.AlignHCenter
        text: Network.wifiEnabled ? "Tidak ada jaringan Wi-Fi" : "Wi-Fi mati"
        color: Appearance.colors.textDim
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.small
        visible: Network.wifiEnabled

        StyledText {
            Layout.fillWidth: true
            text: Network.scanning ? "Memindai..." : `${Network.networks.length} jaringan`
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.small
        }

        TextButton {
            type: "text"
            icon: "refresh"
            text: "Pindai"
            disabled: Network.scanning
            onClicked: Network.scan()
        }
    }

    // VPN dan WireGuard yang tersimpan di NetworkManager; klik = sambung/putus
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.normal
        visible: Network.vpns.length > 0
        spacing: 2

        Caption {
            Layout.leftMargin: Appearance.padding.small
            text: "VPN"
        }

        Repeater {
            model: Network.vpns

            ListRow {
                required property var modelData

                icon: modelData.active ? "vpn_lock" : "vpn_key"
                title: modelData.name
                subtitle: modelData.type === "wireguard" ? "WireGuard" : "VPN"
                active: modelData.active
                onClicked: Network.setVpn(modelData.name, !modelData.active)
            }
        }
    }

    Timer {
        id: rescan

        interval: 2000
        onTriggered: Network.scan()
    }
}
