pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.utils

// Lirik tersinkron dari lrclib.net (ide dari backend lirik Caelestia), di-cache di ~/.cache/me-shell/lyrics.
// Hanya diambil selama ada yang menampilkannya (users > 0), misalnya tab Media.
Singleton {
    id: root

    property int users: 0
    // [{ time (detik), text }] untuk lirik tersinkron; kosong kalau tidak ada
    property var lines: []
    // "", "loading", "none", "ok"
    property string status: ""
    readonly property bool available: lines.length > 0
    readonly property var track: Media.active ? {
        artist: Media.active.trackArtist ?? "",
        title: Media.active.trackTitle ?? "",
        length: Math.round(Media.length)
    } : null
    readonly property string key: track && track.title ? `${track.artist}|${track.title}|${track.length}` : ""
    property string loadedKey: ""
    // Baris yang sedang dinyanyikan (sedikit lebih awal supaya tidak terasa telat)
    readonly property int index: {
        const t = Media.position + 0.3;
        let i = -1;
        for (let n = 0; n < lines.length && lines[n].time <= t; n++)
            i = n;
        return i;
    }

    function parse(lrc: string): var {
        const out = [];
        for (const line of lrc.split("\n")) {
            const m = line.match(/^\[(\d+):(\d+(?:\.\d+)?)\](.*)$/);
            if (m)
                out.push({
                    time: Number(m[1]) * 60 + Number(m[2]),
                    text: m[3].trim()
                });
        }
        return out;
    }

    function fetch(): void {
        if (!Config.lyricsEnabled || users <= 0 || key === "" || key === loadedKey)
            return;
        // Masih mengambil lagu sebelumnya: coba lagi setelah selesai
        if (proc.running) {
            debounce.restart();
            return;
        }
        loadedKey = key;
        lines = [];
        status = "loading";
        const file = `${Paths.cache}/lyrics/${key.replace(/[^\w-]+/g, "_").slice(0, 120)}.json`;
        proc.command = ["sh", "-c", 'f="$1"; [ -s "$f" ] && { cat "$f"; exit; }; mkdir -p "$(dirname "$f")"; curl -fsS --max-time 10 -G "https://lrclib.net/api/search" --data-urlencode "artist_name=$2" --data-urlencode "track_name=$3" -H "User-Agent: me-shell (https://github.com/Adomancer/me-shell)" > "$f.tmp" && mv "$f.tmp" "$f" && cat "$f"', "sh", file, track.artist, track.title];
        proc.running = true;
    }

    onKeyChanged: debounce.restart()
    onUsersChanged: debounce.restart()

    Timer {
        id: debounce

        interval: 600
        onTriggered: root.fetch()
    }

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                let results = [];
                try {
                    results = JSON.parse(text);
                } catch (e) {}
                // Hasil dengan lirik tersinkron dan durasi paling dekat
                const len = root.track?.length ?? 0;
                const best = (Array.isArray(results) ? results : []).filter(r => r.syncedLyrics).sort((a, b) => (len ? Math.abs(a.duration - len) - Math.abs(b.duration - len) : 0) || (a.id - b.id))[0];
                root.lines = best ? root.parse(best.syncedLyrics) : [];
                root.status = root.lines.length > 0 ? "ok" : "none";
            }
        }
    }
}
