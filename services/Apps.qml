pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils
import "../utils/Fuzzy.js" as Fuzzy

// Daftar aplikasi + hitungan berapa kali tiap aplikasi dibuka dari launcher,
// supaya yang sering dipakai naik ke atas (disimpan di ~/.local/state/me-shell/apps.json).
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

    function keyOf(app: var): string {
        return app.id || app.name;
    }

    function uses(app: var): int {
        return adapter.counts[keyOf(app)] ?? 0;
    }

    function search(query: string, max: int): var {
        if (!query)
            return [...all].sort((a, b) => (uses(b) - uses(a)) || a.name.localeCompare(b.name)).slice(0, max);
        // Bonus kecil dari pemakaian: cukup untuk memecah skor yang mirip, tidak menimpa kecocokan nama
        return all.map(a => ({
                    app: a,
                    score: Math.max(Fuzzy.score(query, a.name), Fuzzy.score(query, a.genericName) * 0.6, Fuzzy.score(query, (a.keywords ?? []).join(" ")) * 0.4)
                })).filter(r => r.score > 0).map(r => Object.assign(r, {
                    score: r.score + Math.log(1 + uses(r.app)) * 20
                })).sort((x, y) => (y.score - x.score) || x.app.name.localeCompare(y.app.name)).slice(0, max).map(r => r.app);
    }

    function launch(app: var): void {
        const c = Object.assign({}, adapter.counts);
        c[keyOf(app)] = (c[keyOf(app)] ?? 0) + 1;
        adapter.counts = c;
        file.writeAdapter();
        app.execute();
    }

    FileView {
        id: file

        path: `${Paths.state}/apps.json`

        JsonAdapter {
            id: adapter

            // { "<id aplikasi>": jumlah dibuka }
            property var counts: ({})
        }
    }
}
