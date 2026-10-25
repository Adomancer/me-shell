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

    function submit(): void {
        if (password === "" || busy)
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
                Session.locked = false;
            } else {
                root.failed = true;
                root.message = "AKSES DITOLAK";
            }
        }
    }

    WlSessionLock {
        locked: Session.locked

        WlSessionLockSurface {
            color: Appearance.colors.background

            LockSurface {
                anchors.fill: parent
                lock: root
            }
        }
    }
}
