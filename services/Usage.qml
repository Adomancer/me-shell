pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import qs.services
import qs.utils
import "../utils/Usage.js" as Accounting

Singleton {
    id: root

    property bool ready: false
    // Jeda hanya untuk sesi ini; usageEnabled adalah pilihan permanen.
    property alias paused: persistent.paused
    property string storageError: ""
    property int revision: 0
    property var days: ({})
    property string today: Accounting.dayKey(Date.now())

    readonly property string rawAppId: ToplevelManager.activeToplevel?.appId ?? ""
    readonly property var entry: rawAppId ? DesktopEntries.heuristicLookup(rawAppId) : null
    readonly property string appId: Accounting.normalizeId(entry?.id || rawAppId)
    readonly property bool excluded: Accounting.isExcluded(rawAppId, appId, Config.usageExcludedApps)
    readonly property bool shellFocused: DrawerState.active !== "" && !DrawerState.hoverOpened
    readonly property var categories: Accounting.categoryDefinitions()
    readonly property bool mediaActive: Config.usageMediaAware && Media.players.some(player => player.playbackState === MprisPlaybackState.Playing && root.playerMatches(player.desktopEntry))
    readonly property bool tracking: ready && Config.ready && Config.usageEnabled && !paused && !Session.locked
        && (!activity.isIdle || mediaActive) && appId !== "" && !excluded && !shellFocused
    readonly property string status: !ready || !Config.ready ? "Riwayat belum tersedia" : !Config.usageEnabled ? "Pelacakan dinonaktifkan"
        : paused ? "Pelacakan dijeda" : Session.locked ? "Layar terkunci" : activity.isIdle && !mediaActive ? "Tidak aktif"
        : excluded ? "Aplikasi dikecualikan" : shellFocused ? "Panel shell terbuka"
        : appId === "" ? "Tidak ada aplikasi aktif" : activity.isIdle && mediaActive ? `Media aktif · ${entry?.name || rawAppId}` : `Mencatat ${entry?.name || rawAppId}`
    readonly property int retention: Math.max(21, Math.min(365, Config.usageRetentionDays))
    readonly property string historyPath: `${Paths.state}/usage.json`

    property bool initialized: false
    property bool dirty: false
    property real lastWall: 0
    property var previousApp: null
    property bool previousTracking: false

    function remember(): void {
        persistent.payload = JSON.stringify({ version: 1, days: days });
    }

    function restore(payload: string, transferred: bool): void {
        try {
            days = Accounting.decode(payload);
        } catch (error) {
            storageError = String(error);
            // Never overwrite history we could not understand without an explicit clear.
            ready = false;
            return;
        }
        dirty = transferred;
        remember();
        storageError = "";
        revision++;
        ready = true;
        checkpoint();
        save();
    }

    function snapshot(): void {
        previousApp = { id: appId, name: entry?.name || rawAppId, icon: entry?.icon || "" };
        previousTracking = tracking;
    }

    function checkpoint(): void {
        if (!initialized)
            return;
        const elapsed = monotonic.restart();
        const now = Date.now();
        let changed = false;
        if (ready && Config.ready && previousTracking && now > lastWall
                && Accounting.validInterval(elapsed, (now - lastWall) / 1000)) {
            Accounting.addInterval(days, previousApp, lastWall, now, elapsed);
            changed = true;
        }
        lastWall = now;
        today = Accounting.dayKey(now);
        if (ready && Config.ready && Accounting.prune(days, now, retention))
            changed = true;
        if (changed) {
            dirty = true;
            revision++;
            remember();
        }
        snapshot();
    }

    function save(): void {
        if (!ready || !Config.ready)
            return;
        checkpoint();
        if (!dirty)
            return;
        remember();
        // FileView 0.3 caches failed writes and skips identical setText() calls without
        // a completion signal. Unloading resets that cache; preload:false prevents reads.
        writer.path = "";
        writer.path = historyPath;
        writer.setText(persistent.payload);
    }

    function clearHistory(): void {
        // Explicit user confirmation may replace an unreadable/corrupt history file.
        reader.path = ""; // Cancel any pending initial read so it cannot resurrect cleared data.
        previousTracking = false;
        days = ({});
        dirty = true;
        remember();
        revision++;
        ready = true;
        checkpoint();
        save();
    }

    function playerMatches(desktopId: string): bool {
        if (!desktopId)
            return false;
        const playerEntry = DesktopEntries.heuristicLookup(desktopId);
        return Accounting.mediaMatches(rawAppId, appId, desktopId, playerEntry?.id || "");
    }

    function categoryLabel(id: string): string {
        return categories.find(category => category.id === id)?.label || "Lainnya";
    }

    function categoryOverride(id: string): string {
        return Accounting.categoryOverride(id, Config.usageAppCategories);
    }

    function setCategory(id: string, category: string): void {
        if (!Config.ready || !Accounting.normalizeId(id) || (category !== "" && !categories.some(item => item.id === category)))
            return;
        Config.set("usageAppCategories", Accounting.withCategoryOverride(id, category, Config.usageAppCategories));
    }

    function summary(period: string): var {
        return Accounting.categorize(Accounting.summary(days, period, Date.now()), id => {
            const app = DesktopEntries.heuristicLookup(id);
            return Accounting.categoryFor(id, Array.from(app?.categories || []), Config.usageAppCategories);
        });
    }

    function formatDuration(seconds: real): string {
        return Accounting.formatDuration(seconds);
    }

    onAppIdChanged: checkpoint()
    onTrackingChanged: {
        checkpoint();
        if (!tracking)
            save();
    }
    onRetentionChanged: {
        checkpoint();
        save();
    }

    Component.onCompleted: {
        monotonic.restart();
        lastWall = Date.now();
        initialized = true;
        snapshot();
    }

    Connections {
        target: Config

        function onReadyChanged(): void {
            root.checkpoint();
            root.save();
        }
    }

    // No destructor flush. With healthy storage and timely timers, disk can lag by 30s;
    // reload transfers the last checkpoint, accepting a tail of up to 5s.
    PersistentProperties {
        id: persistent
        reloadableId: "usageHistory"

        property string payload: ""
        property bool paused: false

        onLoaded: {
            if (payload !== "")
                root.restore(payload, true);
            else
                reader.path = root.historyPath;
        }
    }

    ElapsedTimer { id: monotonic }

    IdleMonitor {
        id: activity

        enabled: Config.ready && Config.usageEnabled
        timeout: Math.max(1, Config.usageIdleMinutes) * 60
        // Keep real idle detection: only a matching focused player may bypass it in tracking.
        respectInhibitors: false
    }

    Timer {
        interval: 5000
        running: root.ready && Config.ready
        repeat: true
        onTriggered: root.checkpoint()
    }

    Timer {
        interval: 30000
        running: root.ready && Config.ready
        repeat: true
        onTriggered: root.save()
    }

    FileView {
        id: reader

        // PersistentProperties.loaded chooses disk only when there is no transferred payload.
        path: ""
        printErrors: false
        onLoaded: root.restore(text(), false)
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.remember();
                root.ready = true;
                root.checkpoint();
                root.save();
            } else {
                root.storageError = FileViewError.toString(error);
            }
        }
    }

    FileView {
        id: writer

        path: ""
        preload: false
        blockWrites: true
        atomicWrites: true
        printErrors: false
        onSaved: {
            root.dirty = false;
            root.storageError = "";
        }
        onSaveFailed: error => {
            root.dirty = true;
            root.storageError = FileViewError.toString(error);
        }
    }
}
