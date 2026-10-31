const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

const source = fs.readFileSync(path.join(__dirname, '../services/Usage.qml'), 'utf8');
const accounting = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../utils/Usage.js'), 'utf8'), accounting);
const plain = value => JSON.parse(JSON.stringify(value));
const emptyHistory = JSON.stringify({ version: 1, days: {} });
const history = (seconds, day = '2026-11-01', id = 'firefox') => JSON.stringify({
    version: 1, days: { [day]: { [id]: { name: id, icon: '', seconds } } }
});

// These extractors follow Usage.qml's indentation and fail rather than silently
// substitute a hand-written implementation when its structure changes.
function object(type, id) {
    const match = source.match(new RegExp('^    ' + type + ' \\{\\r?\\n        id: ' + id + '\\b[\\s\\S]*?^    \\}', 'm'));
    assert.ok(match, 'Missing QML object: ' + id);
    return match[0];
}

function handler(text, name, indent = 4) {
    const prefix = ' '.repeat(indent) + name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ': ';
    const block = text.match(new RegExp('^' + prefix + '(?:\\w+ => )?\\{([\\s\\S]*?)^' + ' '.repeat(indent) + '\\}', 'm'));
    if (block)
        return block[1];
    const line = text.match(new RegExp('^' + prefix + '([^\\r\\n]+)', 'm'));
    assert.ok(line, 'Missing QML handler: ' + name);
    return line[1];
}

const methods = Array.from(source.matchAll(/^    function (\w+)\(([^)]*)\): \w+ \{([\s\S]*?)^    \}/gm));
for (const name of ['remember', 'restore', 'snapshot', 'checkpoint', 'save', 'clearHistory', 'playerMatches', 'categoryLabel', 'categoryOverride', 'setCategory', 'summary', 'formatDuration'])
    assert.ok(methods.some(match => match[1] === name), 'Missing service method: ' + name);
const methodSource = methods.map(match => 'function ' + match[1] + '(' + match[2].replace(/:\s*\w+/g, '') + ') {' + match[3] + '\n}').join('\n');
const bindings = Array.from(source.matchAll(/^    readonly property \w+ (\w+): ([^\r\n]*(?:\r?\n {8}\S[^\r\n]*)*)/gm));
for (const name of ['entry', 'appId', 'tracking', 'excluded', 'shellFocused', 'categories', 'mediaActive', 'retention'])
    assert.ok(bindings.some(match => match[1] === name), 'Missing service binding: ' + name);
const persistentSource = object('PersistentProperties', 'persistent');
const readerSource = object('FileView', 'reader');
const writerSource = object('FileView', 'writer');
const configReadyMethod = source.match(/^        function onReadyChanged\(\): void \{([\s\S]*?)^        \}/m);
assert.ok(configReadyMethod, 'Missing Config.ready handler');

function createService({ configReady = true, diskText = null, desktopEntriesReady = true } = {}) {
    const clock = { now: new Date('2026-11-01T12:00:00').getTime(), elapsed: 0 };
    const disk = { text: diskText };
    const entries = {
        firefox: { id: 'firefox.desktop', name: 'Firefox', icon: 'firefox', categories: ['Network', 'WebBrowser'] },
        kitty: { id: 'kitty.desktop', name: 'Kitty', icon: 'kitty', categories: ['System', 'Development'] },
        vlc: { id: 'vlc.desktop', name: 'VLC', icon: 'vlc', categories: ['AudioVideo', 'Player'] }
    };
    const applications = { values: desktopEntriesReady ? Object.values(entries) : [] };
    const context = vm.createContext({
        Accounting: accounting,
        Date: class extends Date { static now() { return clock.now; } },
        Paths: { state: '/state' },
        Config: {
            ready: configReady, usageEnabled: true, usageRetentionDays: 90, usageExcludedApps: [],
            usageMediaAware: false, usageAppCategories: {}, setCalls: [],
            set(key, value) { this.setCalls.push({ key, value: plain(value) }); this[key] = value; }
        },
        Media: { players: [] },
        MprisPlaybackState: { Playing: 1, Paused: 2, Stopped: 3 },
        Session: { locked: false },
        DrawerState: { active: '', hoverOpened: false },
        ToplevelManager: { activeToplevel: { appId: 'firefox' } },
        DesktopEntries: {
            applications,
            heuristicLookup: id => applications.values.find(entry => accounting.normalizeId(entry.id) === accounting.normalizeId(id)) || null
        },
        activity: { isIdle: false },
        mediaLimit: { isIdle: false },
        persistent: { payload: '', paused: false },
        FileViewError: { FileNotFound: 2, PermissionDenied: 3, toString: error => 'FileView error ' + error },
        initialized: false, ready: false, dirty: false, days: {}, revision: 0,
        storageError: '', lastWall: 0, previousApp: null, previousTracking: false,
        monotonic: { restart() { const elapsed = clock.elapsed; clock.elapsed = 0; return elapsed; } }
    });
    context.root = context;
    Object.defineProperty(context, 'paused', {
        get: () => context.persistent.paused,
        set: value => { context.persistent.paused = value; }
    });
    for (const [, name, expression] of bindings) {
        const script = new vm.Script('(' + expression + ')');
        Object.defineProperty(context, name, { get: () => script.runInContext(context) });
    }
    vm.runInContext(methodSource, context);
    const compile = (body, scope) => vm.runInContext('(function(error) { ' + (scope ? 'with (' + scope + ') {' + body + '}' : body) + '\n})', context);
    const signal = name => compile(handler(source, name));
    const onAppIdChanged = signal('onAppIdChanged');
    const onEntryChanged = signal('onEntryChanged');
    const onTrackingChanged = signal('onTrackingChanged');
    const onRetentionChanged = signal('onRetentionChanged');
    const onConfigReadyChanged = compile(configReadyMethod[1]);
    const onPersistentLoaded = compile(handler(persistentSource, 'onLoaded', 8), 'persistent');
    const onReaderLoaded = compile(handler(readerSource, 'onLoaded', 8), 'reader');
    const onReaderLoadFailed = compile(handler(readerSource, 'onLoadFailed', 8));
    const onSaved = compile(handler(writerSource, 'onSaved', 8));
    const onSaveFailed = compile(handler(writerSource, 'onSaveFailed', 8));

    let readerPath = '', pendingRead = false;
    const reader = { loads: 0, text: () => disk.text };
    Object.defineProperty(reader, 'path', {
        get: () => readerPath,
        set(value) {
            if (value === readerPath)
                return;
            readerPath = value;
            pendingRead = value !== '';
            if (pendingRead)
                reader.loads++;
        }
    });
    context.reader = reader;

    // Quickshell 0.3 caches attempted content even on failure, skips identical
    // setText calls without a signal, and clears the cache when path is unloaded.
    let writerPath = '', cached = '';
    const writer = {
        attempts: 0, skipped: 0, fail: false, paths: [], payloads: [],
        setText(text) {
            assert.equal(writerPath, context.historyPath);
            if (text === cached) {
                this.skipped++;
                return;
            }
            cached = text;
            this.attempts++;
            this.payloads.push(text);
            if (this.fail)
                onSaveFailed(context.FileViewError.PermissionDenied);
            else {
                disk.text = text;
                onSaved();
            }
        }
    };
    Object.defineProperty(writer, 'path', {
        get: () => writerPath,
        set(value) {
            writer.paths.push(value);
            if (value !== writerPath) {
                writerPath = value;
                if (value === '')
                    cached = '';
            }
        }
    });
    context.writer = writer;
    signal('Component.onCompleted')();

    return {
        service: context, reader, writer, disk,
        advance(seconds) { clock.now += seconds * 1000; clock.elapsed += seconds; },
        handoff(state) {
            if (state)
                Object.assign(context.persistent, plain(state));
            onPersistentLoaded();
        },
        completeRead() {
            if (!pendingRead)
                return false;
            pendingRead = false;
            if (disk.text === null)
                onReaderLoadFailed(context.FileViewError.FileNotFound);
            else
                onReaderLoaded();
            return true;
        },
        // Node has no QML dependency engine. Explicitly deliver the extracted
        // change handlers in app/entry/tracking/retention/config order, not all possible orders.
        change(update) {
            const before = { app: context.appId, entry: context.entry, tracking: context.tracking, retention: context.retention, config: context.Config.ready };
            update(context);
            if (before.app !== context.appId)
                onAppIdChanged();
            if (before.entry !== context.entry)
                onEntryChanged();
            if (before.tracking !== context.tracking)
                onTrackingChanged();
            if (before.retention !== context.retention)
                onRetentionChanged();
            if (before.config !== context.Config.ready)
                onConfigReadyChanged();
        }
    };
}

function boot(options) {
    const fixture = createService(options);
    fixture.handoff();
    assert.equal(fixture.completeRead(), true);
    return fixture;
}

function seconds(service, id = 'firefox', day = '2026-11-01') {
    return service.days[day]?.[id]?.seconds || 0;
}

test('persistence uses the synchronous writer and no destruction/queued-save machinery', () => {
    assert.match(writerSource, /preload: false/);
    assert.match(writerSource, /blockWrites: true/);
    assert.match(writerSource, /atomicWrites: true/);
    assert.doesNotMatch(source, /Component\.onDestruction|flushAgain|property bool saving/);
    assert.match(source, /property alias paused: persistent\.paused/);
});

test('focus changes credit the previous app before recording the next app', () => {
    const f = boot();
    f.advance(2);
    f.change(s => { s.ToplevelManager.activeToplevel = { appId: 'kitty' }; });
    f.advance(3);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 2);
    assert.equal(seconds(f.service, 'kitty'), 3);
    assert.equal(f.service.previousApp.name, 'Kitty');
    assert.deepEqual(JSON.parse(f.service.persistent.payload).days, plain(f.service.days));
});

test('the entry binding observes the desktop application list and raw app ID', () => {
    const expression = bindings.find(match => match[1] === 'entry')[2];
    assert.match(expression, /DesktopEntries\.applications\.values\s*&&\s*rawAppId/);
    assert.match(expression, /DesktopEntries\.heuristicLookup\(rawAppId\)/);
});

test('desktop entries loading checkpoints upgraded metadata even when the normalized app ID is unchanged', () => {
    const f = boot({ desktopEntriesReady: false });
    assert.deepEqual(f.service.DesktopEntries.applications.values, []);
    assert.equal(f.service.rawAppId, 'firefox');
    assert.equal(f.service.entry, null);
    assert.equal(f.service.appId, 'firefox');
    assert.deepEqual(plain(f.service.previousApp), { id: 'firefox', name: 'firefox', icon: '' });

    f.advance(3);
    f.change(s => {
        s.DesktopEntries.applications.values = [
            { id: 'firefox.desktop', name: 'Firefox', icon: 'firefox', categories: ['Network', 'WebBrowser'] }
        ];
    });
    assert.equal(f.service.rawAppId, 'firefox');
    assert.equal(f.service.entry.id, 'firefox.desktop');
    assert.equal(f.service.appId, 'firefox');
    assert.equal(seconds(f.service), 3);
    assert.deepEqual(plain(f.service.previousApp), { id: 'firefox', name: 'Firefox', icon: 'firefox' });
    assert.deepEqual(plain(f.service.days['2026-11-01'].firefox), { name: 'firefox', icon: '', seconds: 3 });

    f.advance(2);
    f.service.save();
    assert.deepEqual(JSON.parse(f.disk.text).days['2026-11-01'].firefox, {
        name: 'Firefox', icon: 'firefox', seconds: 5
    });
});

const transitions = {
    paused: (s, stopped) => { s.paused = stopped; },
    locked: (s, stopped) => { s.Session.locked = stopped; },
    idle: (s, stopped) => { s.activity.isIdle = stopped; },
    disabled: (s, stopped) => { s.Config.usageEnabled = !stopped; },
    excluded: (s, stopped) => { s.Config.usageExcludedApps = stopped ? ['firefox'] : []; },
    unfocused: (s, stopped) => { s.ToplevelManager.activeToplevel = stopped ? null : { appId: 'firefox' }; }
};
for (const [name, update] of Object.entries(transitions)) {
    test(name + ' transition saves the active interval, skips the stopped interval, and resumes', () => {
        const f = boot();
        f.advance(3);
        f.change(s => update(s, true));
        assert.equal(f.service.tracking, false);
        assert.equal(JSON.parse(f.disk.text).days['2026-11-01'].firefox.seconds, 3);
        f.advance(5);
        f.service.checkpoint();
        assert.equal(seconds(f.service), 3);
        f.change(s => update(s, false));
        assert.equal(f.service.tracking, true);
        f.advance(2);
        f.service.save();
        assert.equal(seconds(f.service), 5);
        assert.equal(f.service.dirty, false);
    });
}

test('hover-open drawers preserve tracking, but pinned drawers suspend it', () => {
    const f = boot();
    f.advance(3);
    f.change(s => { s.DrawerState.active = 'panel'; s.DrawerState.hoverOpened = true; });
    assert.equal(f.service.tracking, true);
    f.advance(2);
    f.change(s => { s.DrawerState.hoverOpened = false; });
    assert.equal(f.service.tracking, false);
    assert.equal(seconds(f.service), 5);
    f.advance(5);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 5);
    f.change(s => { s.DrawerState.active = ''; });
    f.advance(2);
    f.service.save();
    assert.equal(seconds(f.service), 7);
});

function enableIdleMedia(f) {
    f.change(s => {
        s.Config.usageMediaAware = true;
        s.Media.players = [{ desktopEntry: ' Firefox.DESKTOP ', playbackState: s.MprisPlaybackState.Playing }];
        s.activity.isIdle = true;
    });
}

test('media awareness defaults off, so even matching playback cannot bypass idle', () => {
    const f = boot();
    assert.equal(f.service.Config.usageMediaAware, false);
    assert.deepEqual(f.service.Media.players, []);
    f.advance(2);
    f.change(s => {
        s.Media.players = [{ desktopEntry: 'firefox.desktop', playbackState: s.MprisPlaybackState.Playing }];
        s.activity.isIdle = true;
    });
    assert.equal(f.service.mediaActive, false);
    assert.equal(f.service.tracking, false);
    f.advance(5);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 2);
});

test('matching focused playback bypasses idle only while media awareness is enabled', () => {
    const f = boot();
    enableIdleMedia(f);
    assert.equal(f.service.activity.isIdle, true);
    assert.equal(f.service.mediaActive, true);
    assert.equal(f.service.tracking, true);
    f.advance(3);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 3);
    f.advance(2);
    f.change(s => { s.Config.usageMediaAware = false; });
    assert.equal(f.service.mediaActive, false);
    assert.equal(f.service.tracking, false);
    assert.equal(JSON.parse(f.disk.text).days['2026-11-01'].firefox.seconds, 5);
    f.advance(4);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 5);
    f.change(s => { s.Config.usageMediaAware = true; });
    f.advance(2);
    f.service.save();
    assert.equal(seconds(f.service), 7);
});

test('both idle monitors ignore inhibitors and the media cap is one hour', () => {
    const activitySource = object('IdleMonitor', 'activity');
    const mediaLimitSource = object('IdleMonitor', 'mediaLimit');
    for (const monitor of [activitySource, mediaLimitSource]) {
        assert.match(monitor, /enabled: Config\.ready && Config\.usageEnabled/);
        assert.match(monitor, /respectInhibitors: false/);
    }
    assert.match(mediaLimitSource, /timeout: 60\s*\*\s*60\s*\r?\n/);
});

test('the media idle cap stops matching playback without retroactive counting and input resumes tracking', () => {
    const f = boot();
    assert.equal(f.service.mediaLimit.isIdle, false);
    enableIdleMedia(f);
    f.advance(3);
    f.service.checkpoint();
    f.advance(2);
    f.change(s => { s.mediaLimit.isIdle = true; });
    assert.equal(f.service.activity.isIdle, true);
    assert.equal(f.service.Media.players[0].playbackState, f.service.MprisPlaybackState.Playing);
    assert.equal(f.service.playerMatches(f.service.Media.players[0].desktopEntry), true);
    assert.equal(f.service.mediaActive, false);
    assert.equal(f.service.tracking, false);
    assert.equal(f.service.previousTracking, false);
    assert.equal(JSON.parse(f.disk.text).days['2026-11-01'].firefox.seconds, 5);

    f.advance(4);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 5);
    f.advance(2);
    f.change(s => {
        s.activity.isIdle = false;
        s.mediaLimit.isIdle = false;
    });
    assert.equal(f.service.activity.isIdle, false);
    assert.equal(f.service.mediaLimit.isIdle, false);
    assert.equal(f.service.mediaActive, true);
    assert.equal(f.service.tracking, true);
    assert.equal(seconds(f.service), 5);
    f.advance(2);
    f.service.save();
    assert.equal(seconds(f.service), 7);

    f.change(s => { s.activity.isIdle = true; });
    assert.equal(f.service.mediaActive, true);
    assert.equal(f.service.tracking, true);
    f.advance(1);
    f.service.save();
    assert.equal(JSON.parse(f.disk.text).days['2026-11-01'].firefox.seconds, 8);
});

for (const [name, player] of Object.entries({
    unrelated: { desktopEntry: 'vlc.desktop' },
    'similar but not matching': { desktopEntry: 'firefox-nightly.desktop' },
    'missing desktop entry': {},
    'empty desktop entry': { desktopEntry: '' }
})) {
    test(name + ' playing media cannot bypass idle or count background playback', () => {
        const f = boot();
        f.advance(2);
        f.change(s => {
            s.Config.usageMediaAware = true;
            s.Media.players = [{ ...player, playbackState: s.MprisPlaybackState.Playing }];
            s.activity.isIdle = true;
        });
        assert.equal(f.service.mediaActive, false);
        assert.equal(f.service.tracking, false);
        f.advance(5);
        f.service.checkpoint();
        assert.equal(seconds(f.service), 2);
        assert.equal(seconds(f.service, 'vlc'), 0);
        assert.deepEqual(Object.keys(f.service.days['2026-11-01']), ['firefox']);
    });
}

for (const state of ['Paused', 'Stopped', 'removed']) {
    test(state + ' matching player stops idle accounting and playback can resume it', () => {
        const f = boot();
        enableIdleMedia(f);
        f.advance(3);
        f.change(s => {
            if (state === 'removed')
                s.Media.players = [];
            else
                s.Media.players[0].playbackState = s.MprisPlaybackState[state];
        });
        assert.equal(f.service.mediaActive, false);
        assert.equal(f.service.tracking, false);
        assert.equal(JSON.parse(f.disk.text).days['2026-11-01'].firefox.seconds, 3);
        f.advance(5);
        f.service.checkpoint();
        assert.equal(seconds(f.service), 3);
        enableIdleMedia(f);
        f.advance(2);
        f.service.save();
        assert.equal(seconds(f.service), 5);
    });
}

test('media matching checks every player, not just Media.active or the first player', () => {
    const f = boot();
    enableIdleMedia(f);
    f.change(s => {
        s.Media.players = [
            { desktopEntry: 'vlc.desktop', playbackState: s.MprisPlaybackState.Playing },
            { desktopEntry: 'firefox', playbackState: s.MprisPlaybackState.Paused },
            { desktopEntry: 'firefox.desktop', playbackState: s.MprisPlaybackState.Playing }
        ];
        s.Media.active = s.Media.players[0];
    });
    assert.equal(f.service.mediaActive, true);
    assert.equal(f.service.tracking, true);
    f.advance(3);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 3);
    assert.equal(seconds(f.service, 'vlc'), 0);
    f.change(s => { s.Media.players.pop(); });
    assert.equal(f.service.mediaActive, false);
    assert.equal(f.service.tracking, false);
    f.advance(4);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 3);
});

test('player matching resolves canonical desktop IDs and rejects a missing player ID', () => {
    const f = boot();
    const lookup = f.service.DesktopEntries.heuristicLookup;
    f.service.DesktopEntries.heuristicLookup = id => id === 'browser-alias' ? lookup('firefox.desktop') : lookup(id);
    enableIdleMedia(f);
    f.change(s => { s.Media.players[0].desktopEntry = 'browser-alias'; });
    assert.equal(f.service.playerMatches('browser-alias'), true);
    assert.equal(f.service.playerMatches(undefined), false);
    assert.equal(f.service.mediaActive, true);
    f.advance(2);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 2);
});

test('idle focus switches credit the previous app and never count its background player', () => {
    const f = boot();
    enableIdleMedia(f);
    f.advance(3);
    f.change(s => { s.ToplevelManager.activeToplevel = { appId: 'kitty.desktop' }; });
    assert.equal(seconds(f.service), 3);
    assert.equal(f.service.previousApp.id, 'kitty');
    assert.equal(f.service.tracking, false);
    f.advance(4);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 3);
    assert.equal(seconds(f.service, 'kitty'), 0);
    f.change(s => { s.Media.players.push({ desktopEntry: 'kitty', playbackState: s.MprisPlaybackState.Playing }); });
    assert.equal(f.service.tracking, true);
    f.advance(2);
    f.change(s => { s.ToplevelManager.activeToplevel = { appId: 'firefox.desktop' }; });
    assert.equal(seconds(f.service, 'kitty'), 2);
    assert.equal(seconds(f.service), 3);
    f.advance(1);
    f.service.save();
    assert.equal(seconds(f.service), 4);
    assert.equal(seconds(f.service, 'kitty'), 2);
    assert.equal(f.service.summary('today').total, 6);
});

for (const [name, update] of Object.entries({
    paused: transitions.paused,
    locked: transitions.locked,
    disabled: transitions.disabled,
    excluded: transitions.excluded,
    'shell focused': (s, stopped) => { s.DrawerState.active = stopped ? 'panel' : ''; }
})) {
    test(name + ' still suspends tracking despite matching idle media', () => {
        const f = boot();
        enableIdleMedia(f);
        f.advance(3);
        f.change(s => update(s, true));
        assert.equal(f.service.mediaActive, true);
        assert.equal(f.service.tracking, false);
        assert.equal(JSON.parse(f.disk.text).days['2026-11-01'].firefox.seconds, 3);
        f.advance(5);
        f.service.checkpoint();
        assert.equal(seconds(f.service), 3);
        f.change(s => update(s, false));
        assert.equal(f.service.tracking, true);
        f.advance(2);
        f.service.save();
        assert.equal(seconds(f.service), 5);
    });
}

test('missing focus cannot be replaced by a playing media app', () => {
    const f = boot();
    enableIdleMedia(f);
    f.advance(2);
    f.change(s => { s.ToplevelManager.activeToplevel = null; });
    assert.equal(f.service.mediaActive, false);
    assert.equal(f.service.tracking, false);
    f.advance(4);
    f.service.checkpoint();
    assert.equal(seconds(f.service), 2);
});

test('initial config gating prevents accounting and premature retention pruning', () => {
    const f = boot({ configReady: false, diskText: history(60, '2026-01-01') });
    assert.equal(f.service.ready, true);
    assert.equal(f.service.tracking, false);
    f.advance(5);
    f.service.checkpoint();
    f.service.save();
    assert.equal(seconds(f.service, 'firefox', '2026-01-01'), 60);
    assert.equal(seconds(f.service), 0);
    assert.equal(f.writer.attempts, 0);
    f.change(s => { s.Config.usageRetentionDays = 365; });
    f.change(s => { s.Config.ready = true; });
    assert.equal(f.service.tracking, true);
    assert.equal(seconds(f.service, 'firefox', '2026-01-01'), 60);
    f.advance(5);
    f.service.save();
    assert.equal(seconds(f.service), 5);
    assert.equal(JSON.parse(f.disk.text).days['2026-01-01'].firefox.seconds, 60);
});

test('clearing before config readiness keeps the clear pending until readiness', () => {
    const f = boot({ configReady: false, diskText: history(60) });
    f.service.clearHistory();
    assert.equal(f.service.dirty, true);
    assert.equal(f.writer.attempts, 0);
    assert.equal(f.disk.text, history(60));
    f.change(s => { s.Config.ready = true; });
    assert.equal(f.disk.text, emptyHistory);
    assert.equal(f.service.dirty, false);
});

test('save checkpoints the latest interval before synchronously writing', () => {
    const f = boot();
    f.advance(5);
    f.service.save();
    assert.equal(JSON.parse(f.disk.text).days['2026-11-01'].firefox.seconds, 5);
    assert.equal(f.service.dirty, false);
    f.service.save();
    assert.equal(f.writer.attempts, 1);
});

test('repeated identical clears reset the writer cache and complete every time', () => {
    const f = boot();
    f.service.clearHistory();
    f.service.clearHistory();
    assert.equal(f.writer.attempts, 2);
    assert.equal(f.writer.skipped, 0);
    assert.deepEqual(f.writer.paths, ['', f.service.historyPath, '', f.service.historyPath]);
    assert.equal(f.disk.text, emptyHistory);
    assert.equal(f.service.dirty, false);
});

test('failed identical payloads retry after cache reset and retain dirty/error until success', () => {
    const f = boot({ diskText: emptyHistory });
    f.writer.fail = true;
    f.advance(5);
    f.service.save();
    const payload = f.service.persistent.payload;
    assert.equal(f.service.dirty, true);
    assert.notEqual(f.service.storageError, '');
    assert.equal(f.disk.text, emptyHistory);
    f.service.save();
    assert.equal(f.writer.attempts, 2);
    assert.equal(f.service.dirty, true);
    f.writer.fail = false;
    f.service.save();
    assert.equal(f.writer.attempts, 3);
    assert.equal(f.writer.skipped, 0);
    assert.deepEqual(f.writer.payloads, [payload, payload, payload]);
    assert.equal(f.disk.text, payload);
    assert.equal(f.service.dirty, false);
    assert.equal(f.service.storageError, '');
});

test('clear cancels a pending initial read so old data cannot be resurrected', () => {
    const f = createService({ diskText: history(90) });
    assert.equal(f.reader.loads, 0);
    f.handoff();
    assert.equal(f.reader.loads, 1);
    f.service.clearHistory();
    assert.equal(f.reader.path, '');
    assert.equal(f.completeRead(), false);
    assert.deepEqual(plain(f.service.days), {});
    assert.equal(f.disk.text, emptyHistory);
});

test('reload transfers checkpointed history and paused state instead of reading stale disk', () => {
    const old = boot();
    old.advance(5);
    old.service.checkpoint();
    old.service.paused = true;
    old.advance(4); // No final checkpoint: only the documented reload tail is lost.
    const f = createService({ diskText: history(1) });
    assert.equal(f.reader.loads, 0);
    f.handoff(old.service.persistent);
    assert.equal(f.reader.loads, 0);
    assert.equal(f.completeRead(), false);
    assert.equal(f.service.paused, true);
    assert.equal(f.service.tracking, false);
    assert.equal(seconds(f.service), 5);
    assert.equal(JSON.parse(f.disk.text).days['2026-11-01'].firefox.seconds, 5);
});

test('transferred history remains authoritative and dirty until config becomes ready', () => {
    const f = createService({ configReady: false, diskText: history(1) });
    f.handoff({ payload: history(42), paused: true });
    assert.equal(f.reader.loads, 0);
    assert.equal(seconds(f.service), 42);
    assert.equal(f.service.dirty, true);
    assert.equal(f.writer.attempts, 0);
    f.change(s => { s.Config.ready = true; });
    assert.equal(JSON.parse(f.disk.text).days['2026-11-01'].firefox.seconds, 42);
    assert.equal(f.service.paused, true);
    assert.equal(f.service.dirty, false);
});

for (const [name, payload] of Object.entries({
    malformed: 'broken json',
    unsupported: JSON.stringify({ version: 2, days: {} }),
    invalidDuration: history(-1)
})) {
    test(name + ' disk history cannot be overwritten without an explicit clear', () => {
        const f = boot({ diskText: payload });
        assert.equal(f.service.ready, false);
        assert.notEqual(f.service.storageError, '');
        assert.equal(f.service.persistent.payload, '');
        f.advance(5);
        f.service.checkpoint();
        f.service.dirty = true;
        f.service.save();
        assert.equal(f.writer.attempts, 0);
        assert.equal(f.disk.text, payload);
        f.service.clearHistory();
        assert.equal(f.disk.text, emptyHistory);
        assert.equal(f.service.ready, true);
        assert.equal(f.service.storageError, '');
    });
}

test('invalid transferred history neither falls back to disk nor overwrites it', () => {
    const f = createService({ diskText: history(30) });
    f.handoff({ payload: 'broken transfer', paused: true });
    f.service.save();
    assert.equal(f.service.ready, false);
    assert.equal(f.reader.loads, 0);
    assert.equal(f.writer.attempts, 0);
    assert.equal(f.disk.text, history(30));
});

test('clean disk history is not rewritten merely by loading or saving', () => {
    const f = boot({ diskText: history(30) });
    f.service.save();
    assert.equal(seconds(f.service), 30);
    assert.equal(f.writer.attempts, 0);
});

test('category definitions and labels come from the readonly service binding', () => {
    const f = boot();
    assert.equal(Object.getOwnPropertyDescriptor(f.service, 'categories').set, undefined);
    assert.deepEqual(plain(f.service.categories), [
        { id: 'development', label: 'Pengembangan', icon: 'code' },
        { id: 'entertainment', label: 'Hiburan', icon: 'movie' },
        { id: 'communication', label: 'Komunikasi', icon: 'forum' },
        { id: 'productivity', label: 'Produktivitas', icon: 'work' },
        { id: 'browsing', label: 'Browsing', icon: 'language' },
        { id: 'other', label: 'Lainnya', icon: 'apps' }
    ]);
    for (const category of f.service.categories)
        assert.equal(f.service.categoryLabel(category.id), category.label);
    assert.equal(f.service.categoryLabel('unknown'), 'Lainnya');
    assert.deepEqual(plain(f.service.Config.usageAppCategories), {});
    const report = f.service.summary('today');
    assert.equal(report.total, 0);
    assert.deepEqual(plain(report.apps), []);
    assert.deepEqual(plain(report.categories), plain(f.service.categories).map(category => ({ ...category, seconds: 0 })));
});

test('category summaries and config edits reclassify historical usage without mutating days', () => {
    const record = (name, seconds) => ({ name, icon: '', seconds });
    const diskText = JSON.stringify({ version: 1, days: {
        '2026-10-25': { firefox: record('Firefox', 50) },
        '2026-10-31': { firefox: record('Firefox', 40) },
        '2026-11-01': {
            firefox: record('Firefox', 60), kitty: record('Kitty', 30),
            vlc: record('VLC', 20), missing: record('Missing desktop entry', 10)
        }
    } });
    const f = boot({ diskText });
    const days = f.service.days;
    const before = plain(days);
    const payload = f.service.persistent.payload;
    const revision = f.service.revision;
    const reports = Object.fromEntries(['today', 'week', 'lastWeek', 'month', 'lastMonth'].map(period => [period, plain(f.service.summary(period))]));
    assert.equal(reports.today.total, 120);
    assert.equal(reports.today.previousTotal, 40);
    assert.equal(reports.week.total, 160);
    assert.equal(reports.lastWeek.total, 50);
    assert.equal(reports.month.total, 120);
    assert.equal(reports.month.average, 120);
    assert.equal(reports.month.comparisonDays, 1);
    assert.equal(reports.month.previousTotal, 0);
    assert.equal(reports.month.days.length, 30);
    assert.equal(reports.lastMonth.total, 90);
    assert.equal(reports.lastMonth.average, 90 / 31);
    assert.equal(reports.lastMonth.days.length, 31);
    assert.deepEqual(Object.fromEntries(reports.today.apps.map(app => [app.id, app.category])), {
        firefox: 'browsing', kitty: 'development', vlc: 'entertainment', missing: 'other'
    });
    assert.deepEqual(Object.fromEntries(reports.today.categories.map(category => [category.id, category.seconds])), {
        development: 30, entertainment: 20, communication: 0, productivity: 0, browsing: 60, other: 10
    });
    const checkReports = category => {
        for (const period of Object.keys(reports)) {
            const report = plain(f.service.summary(period));
            assert.equal(report.apps.find(app => app.id === 'firefox').category, category);
            assert.equal(report.categories.reduce((total, item) => total + item.seconds, 0), report.total);
            assert.equal(report.apps.reduce((total, app) => total + app.seconds, 0), report.total);
            const uncategorized = ({ categories, apps, ...rest }) => ({ ...rest, apps: apps.map(({ category, ...app }) => app) });
            assert.deepEqual(uncategorized(report), uncategorized(reports[period]));
        }
        assert.strictEqual(f.service.days, days);
        assert.deepEqual(plain(days), before);
        assert.equal(f.service.persistent.payload, payload);
        assert.equal(f.service.revision, revision);
        assert.equal(f.service.dirty, false);
        assert.equal(f.writer.attempts, 0);
        assert.equal(f.disk.text, diskText);
    };
    checkReports('browsing');
    assert.equal(f.service.categoryOverride('firefox'), '');
    f.service.setCategory(' Firefox.DESKTOP ', 'entertainment');
    assert.equal(f.service.categoryOverride('FIREFOX.desktop'), 'entertainment');
    assert.deepEqual(plain(f.service.Config.setCalls), [{ key: 'usageAppCategories', value: { firefox: 'entertainment' } }]);
    checkReports('entertainment');
    assert.equal(f.service.summary('today').categories.find(category => category.id === 'entertainment').seconds, 80);
    f.change(s => { s.Config.set('usageAppCategories', { ' FIREFOX.desktop ': 'communication', kitty: 'productivity' }); });
    assert.equal(f.service.categoryOverride('firefox'), 'communication');
    checkReports('communication');
    assert.equal(f.service.summary('today').apps.find(app => app.id === 'kitty').category, 'productivity');
    f.service.setCategory('firefox.desktop', '');
    assert.equal(f.service.categoryOverride('firefox'), '');
    assert.deepEqual(plain(f.service.Config.usageAppCategories), { kitty: 'productivity' });
    checkReports('browsing');
    f.change(s => { s.Config.set('usageAppCategories', {}); });
    for (const period of Object.keys(reports))
        assert.deepEqual(plain(f.service.summary(period)), reports[period]);
    checkReports('browsing');
});

test('category edits canonicalize equivalent overrides and reset only the requested app', () => {
    const f = boot();
    const original = { FIREFOX: 'development', ' Firefox.desktop ': 'entertainment', kitty: 'productivity' };
    const before = plain(original);
    f.service.Config.usageAppCategories = original;
    f.service.setCategory(' FIREFOX.desktop ', 'communication');
    assert.deepEqual(original, before);
    assert.deepEqual(plain(f.service.Config.usageAppCategories), { kitty: 'productivity', firefox: 'communication' });
    assert.equal(f.service.categoryOverride('firefox.desktop'), 'communication');
    f.service.setCategory('Firefox', '');
    assert.deepEqual(plain(f.service.Config.usageAppCategories), { kitty: 'productivity' });
    assert.equal(f.service.categoryOverride('firefox'), '');
    assert.equal(f.service.Config.setCalls.length, 2);
});

test('category edits reject invalid IDs, categories and config that is not ready', () => {
    const f = boot();
    for (const [id, category] of [['', 'browsing'], ['   ', 'other'], ['firefox', 'unknown']])
        f.service.setCategory(id, category);
    f.change(s => { s.Config.ready = false; });
    f.service.setCategory('firefox', 'entertainment');
    f.service.setCategory('firefox', '');
    assert.deepEqual(plain(f.service.Config.setCalls), []);
    assert.deepEqual(plain(f.service.Config.usageAppCategories), {});
});

test('the actual retention binding clamps to 21 through 365 days', () => {
    const f = boot();
    f.service.Config.usageRetentionDays = 7;
    assert.equal(f.service.retention, 21);
    f.service.Config.usageRetentionDays = 999;
    assert.equal(f.service.retention, 365);
});
