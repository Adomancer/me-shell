pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.utils

// Daftar tugas sederhana (ide dari todo end-4), disimpan di ~/.local/state/me-shell/todo.json.
Singleton {
    id: root

    // [{ id, text, done }], urutan tambah
    readonly property var items: adapter.items
    readonly property int pending: items.filter(t => !t.done).length

    function save(list: var): void {
        adapter.items = list;
        file.writeAdapter();
    }

    function add(text: string): void {
        const t = text.trim();
        if (!t)
            return;
        save([...items, {
                id: Date.now(),
                text: t,
                done: false
            }]);
        Toaster.show("checklist", "Tugas ditambahkan", t, "");
    }

    function toggle(id: real): void {
        save(items.map(t => t.id === id ? Object.assign({}, t, {
                done: !t.done
            }) : t));
    }

    function remove(id: real): void {
        save(items.filter(t => t.id !== id));
    }

    function clearDone(): void {
        save(items.filter(t => !t.done));
    }

    FileView {
        id: file

        path: `${Paths.state}/todo.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property var items: []
        }
    }

    IpcHandler {
        target: "todo"

        function add(text: string): void {
            root.add(text);
        }

        function list(): string {
            return root.items.map((t, i) => `${t.done ? "[x]" : "[ ]"} ${i + 1}. ${t.text}`).join("\n");
        }
    }
}
