import Quickshell
import qs.modules.bar

ShellRoot {
    // Satu bar untuk setiap monitor
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
