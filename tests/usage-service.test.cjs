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
for (const name of ['remember', 'restore', 'snapshot', 'checkpoint', 'save', 'clearHistory', 'summary', 'formatDuration'])
    assert.ok(methods.some(match => match[1] === name), 'Missing service method: ' + name);
const methodSource = methods.map(match => 'function ' + match[1] + '(' + match[2].replace(/:\s*\w+/g, '') + ') {' + match[3] + '\n}').join('\n');
const bindings = Array.from(source.matchAll(/^    readonly property \w+ (\w+): ([^\r\n]*(?:\r?\n {8}\S[^\r\n]*)*)/gm));
for (const name of ['appId', 'tracking', 'excluded', 'shellFocused', 'retention'])
    assert.ok(bindings.some(match => match[1] === name), 'Missing service binding: ' + name);
const persistentSource = object('PersistentProperties', 'persistent');
const readerSource = object('FileView', 'reader');
const writerSource = object('FileView', 'writer');
const configReadyMethod = source.match(/^        function onReadyChanged\(\): void \{([\s\S]*?)^        \}/m);
assert.ok(configReadyMethod, 'Missing Config.ready handler');

function createService({ configReady = true, diskText = null } = {}) {
    const clock = { now: new Date('2026-11-01T12:00:00').getTime(), elapsed: 0 };
    const disk = { text: diskText };
    const entries = {
        firefox: { id: 'firefox.desktop', name: 'Firefox', icon: 'firefox' },
        kitty: { id: 'kitty.desktop', name: 'Kitty', icon: 'kitty' }
    };
    const context = vm.createContext({
        Accounting: accounting,
        Date: class extends Date { static now() { return clock.now; } },
        Paths: { state: '/state' },
        Config: { ready: configReady, usageEnabled: true, usageRetentionDays: 90, usageExcludedApps: [] },
        Session: { locked: false },
        DrawerState: { active: '', hoverOpened: false },
        ToplevelManager: { activeToplevel: { appId: 'firefox' } },
        DesktopEntries: { heuristicLookup: id => entries[id] || null },
        activity: { isIdle: false },
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
        // change handlers in app/tracking/retention/config order, not all possible orders.
        change(update) {
            const before = { app: context.appId, tracking: context.tracking, retention: context.retention, config: context.Config.ready };
            update(context);
            if (before.app !== context.appId)
                onAppIdChanged();
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

test('the actual retention binding clamps to 21 through 365 days', () => {
    const f = boot();
    f.service.Config.usageRetentionDays = 7;
    assert.equal(f.service.retention, 21);
    f.service.Config.usageRetentionDays = 999;
    assert.equal(f.service.retention, 365);
});
