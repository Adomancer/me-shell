import QtQuick

// Isi drawer yang baru dibuat saat pertama kali dibuka di monitor ini, lalu dipertahankan (buka berikutnya
// tidak membuat ulang). `shown` di-bind setelah item jadi, supaya onShownChanged di isi tetap terpanggil
// pada pembukaan pertama (fokus keyboard, isi kolom cari, dsb.).
Loader {
    id: root

    required property Wrapper wrapper

    // Diset sekali secara imperatif; binding ke wrapper.shown akan membongkar isi saat ditutup
    active: false

    onLoaded: item.shown = Qt.binding(() => root.wrapper.shown)

    Connections {
        target: root.wrapper

        function onShownChanged(): void {
            if (root.wrapper.shown)
                root.active = true;
        }
    }
}
