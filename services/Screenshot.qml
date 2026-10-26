pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.utils

// Screenshot lewat grim: disimpan ke Config.screenshotDir dan langsung disalin ke clipboard.
// Area dipilih oleh modules/picker; di sini hanya mengambil gambarnya.
Singleton {
    id: root

    // Diisi oleh picker: "screenshot", "record", atau "ocr"; dibaca saat picker selesai
    property string pickerMode: "screenshot"
    property bool pickerOpen: false
    // Argumen grim untuk tangkapan berikutnya
    property var pending: []

    function stamp(): string {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
    }

    // Layar penuh monitor yang sedang fokus. Ditunda sedikit supaya drawer sempat tertutup.
    function full(): void {
        DrawerState.close();
        pending = ["-o", Hyprland.focusedMonitor?.name ?? ""];
        delay.restart();
    }

    // Koordinat global (logical) dari picker
    function region(x: real, y: real, w: real, h: real): void {
        pending = ["-g", `${Math.round(x)},${Math.round(y)} ${Math.round(w)}x${Math.round(h)}`];
        if (pickerMode === "ocr")
            ocrDelay.restart();
        else
            delay.restart();
    }

    // hyprpicker membekukan layar sendiri; tunggu drawer tertutup dulu
    function pickColor(): void {
        DrawerState.close();
        colorDelay.restart();
    }

    function openPicker(mode: string): void {
        DrawerState.close();
        pickerMode = mode;
        pickerOpen = true;
    }

    Timer {
        id: delay

        interval: 250
        onTriggered: {
            const file = `${Config.screenshotDir}/Screenshot_${root.stamp()}.png`;
            proc.file = file;
            proc.command = ["sh", "-c", 'f="$1"; shift; mkdir -p "$(dirname "$f")" && grim "$@" "$f" && wl-copy --type image/png < "$f"', "sh", file, ...root.pending];
            proc.running = true;
        }
    }

    // OCR (ide dari regionSelector end-4): area -> tesseract -> clipboard. Bahasa Inggris + Indonesia
    // kalau data bahasanya ada.
    Timer {
        id: ocrDelay

        interval: 250
        onTriggered: {
            ocrProc.command = ["sh", "-c", 'command -v tesseract >/dev/null || { echo "#no-tesseract"; exit; }; l=eng; tesseract --list-langs 2>/dev/null | grep -qx ind && l=eng+ind; grim "$@" - | tesseract - - -l "$l" 2>/dev/null', "sh", ...root.pending];
            ocrProc.running = true;
        }
    }

    Process {
        id: ocrProc

        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t === "#no-tesseract") {
                    Toaster.show("error", "OCR gagal", "tesseract belum terinstall", "");
                } else if (!t) {
                    Toaster.show("document_scanner", "Tidak ada teks", "Coba area yang lebih besar atau lebih jelas", "");
                } else {
                    Quickshell.execDetached(["wl-copy", t]);
                    Toaster.show("document_scanner", "Teks disalin", t.replace(/\s+/g, " ").slice(0, 80), "");
                }
            }
        }
    }

    Timer {
        id: colorDelay

        interval: 250
        onTriggered: colorProc.running = true
    }

    Process {
        id: colorProc

        command: ["hyprpicker", "-a", "-f", "hex"]
        stdout: StdioCollector {
            onStreamFinished: {
                const c = text.trim();
                if (c)
                    Toaster.show("colorize", "Warna disalin", c, "");
            }
        }
    }

    Process {
        id: proc

        property string file

        onExited: code => {
            if (code === 0)
                Toaster.show("screenshot_region", "Screenshot disimpan", "Sudah disalin ke clipboard", file);
            else
                Toaster.show("error", "Screenshot gagal", "Pastikan grim dan wl-clipboard terinstall", "");
        }
    }

    IpcHandler {
        target: "picker"

        function open(): void {
            root.openPicker("screenshot");
        }

        function record(): void {
            root.openPicker("record");
        }

        function screen(): void {
            root.full();
        }

        function color(): void {
            root.pickColor();
        }

        function ocr(): void {
            root.openPicker("ocr");
        }
    }
}
