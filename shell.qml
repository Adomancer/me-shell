//@ pragma UseQApplication

import Quickshell
import QtQuick
import qs.services
import qs.modules.background
import qs.modules.drawers
import qs.modules.lock

ShellRoot {
    Component.onCompleted: {
        Keybinds.ensureFiles();
        // Singleton baru dibuat saat pertama disentuh; service latar ini harus jalan sejak start
        Idle.inhibited;
        Clipboard.watching;
    }

    Background {}

    Lock {}

    // Bar + drawer untuk setiap monitor
    Variants {
        model: Quickshell.screens

        Drawers {}
    }
}
