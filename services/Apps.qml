pragma Singleton

import Quickshell
import QtQuick
import "../utils/Fuzzy.js" as Fuzzy

Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

    function search(query: string, max: int): var {
        if (!query)
            return all.slice(0, max);
        return all.map(a => ({
                    app: a,
                    score: Math.max(Fuzzy.score(query, a.name), Fuzzy.score(query, a.genericName) * 0.6, Fuzzy.score(query, (a.keywords ?? []).join(" ")) * 0.4)
                })).filter(r => r.score > 0).sort((x, y) => y.score - x.score).slice(0, max).map(r => r.app);
    }
}
