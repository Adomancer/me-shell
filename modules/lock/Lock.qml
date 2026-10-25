import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import qs.services
import qs.utils

// Lockscreen asli (ext-session-lock). Dipicu lewat Session.lock() / `ipc call lock lock`.
// PENTING: set `misc:allow_session_lock_restore = true` di hyprland.conf.
Scope {
    id: root

    // Dibagi ke semua monitor supaya ketikan sama di mana pun
    property string password: ""
    property bool busy: false
    property bool failed: false
    property string message: ""
    // true = password benar, animasi keluar sedang berjalan sebelum sesi dibuka
    property bool unlocking: false

    function submit(): void {
        if (password === "" || busy || unlocking)
            return;
        busy = true;
        message = "";
        pam.start();
    }

    PamContext {
        id: pam

        configDirectory: `${Paths.shell}/assets/pam`
        config: "password.conf"

        onPamMessage: {
            if (pam.responseRequired)
                pam.respond(root.password);
            else if (pam.messageIsError)
                root.message = pam.message;
        }

        onCompleted: result => {
            root.busy = false;
            root.password = "";
            if (result === PamResult.Success) {
                root.failed = false;
                root.message = "";
                root.unlocking = true;
                unlockTimer.restart();
            } else {
                root.failed = true;
                root.message = "Password salah";
            }
        }
    }

    // Beri waktu animasi keluar sebelum permukaan lock dihancurkan
    Timer {
        id: unlockTimer

        interval: Appearance.anim.durations.large
        onTriggered: {
            Session.locked = false;
            root.unlocking = false;
        }
    }

    WlSessionLock {
        locked: Session.locked

        WlSessionLockSurface {
            color: "black"

            LockSurface {
                anchors.fill: parent
                lock: root
            }
        }
    }
}
