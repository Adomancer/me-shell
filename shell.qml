//@ pragma UseQApplication

import Quickshell
import qs.services
import qs.modules.background
import qs.modules.drawers
import qs.modules.lock

ShellRoot {
    Component.onCompleted: Keybinds.ensureFiles()

    Background {}

    Lock {}

    // Bar + drawer untuk setiap monitor
    Variants {
        model: Quickshell.screens

        Drawers {}
    }
}
