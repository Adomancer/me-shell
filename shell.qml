//@ pragma UseQApplication

import Quickshell
import qs.modules.background
import qs.modules.drawers
import qs.modules.lock

ShellRoot {
    Background {}

    Lock {}

    // Bar + drawer untuk setiap monitor
    Variants {
        model: Quickshell.screens

        Drawers {}
    }
}
