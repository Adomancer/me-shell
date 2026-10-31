const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');
const { execFileSync } = require('node:child_process');

// Run the exact QML JavaScript helpers without introducing a runtime dependency.
const accounting = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../utils/Usage.js'), 'utf8'), accounting);
const plain = value => JSON.parse(JSON.stringify(value));
const app = { id: 'firefox', name: 'Firefox', icon: 'firefox' };
const date = text => new Date(text).getTime();

function record(days, id, day, seconds) {
    accounting.addInterval(days, { id, name: id, icon: '' }, date(`${day}T12:00:00`), date(`${day}T12:00:10`), seconds);
}

test('accumulates only the supplied focused app and merges sessions', () => {
    const days = {};
    accounting.addInterval(days, app, date('2026-11-02T12:00:00'), date('2026-11-02T12:00:05'), 5);
    accounting.addInterval(days, app, date('2026-11-02T12:01:00'), date('2026-11-02T12:01:05'), 5);
    assert.equal(days['2026-11-02'].firefox.seconds, 10);
    assert.deepEqual(Object.keys(days['2026-11-02'].firefox).sort(), ['icon', 'name', 'seconds']);
});

test('splits an interval at local midnight, including year rollover', () => {
    const days = {};
    accounting.addInterval(days, app, date('2026-12-31T23:59:58'), date('2027-01-01T00:00:03'), 5);
    assert.equal(days['2026-12-31'].firefox.seconds, 2);
    assert.equal(days['2027-01-01'].firefox.seconds, 3);
});

test('clock guards discard suspend gaps, stalls, backward clocks and clock corrections', () => {
    assert.equal(accounting.validInterval(5, 5.01), true);
    assert.equal(accounting.validInterval(5, 0), false);
    assert.equal(accounting.validInterval(5, -5), false);
    assert.equal(accounting.validInterval(5, 3605), false);
    assert.equal(accounting.validInterval(3605, 3605), false);
    assert.equal(accounting.validInterval(0, 0), false);
    assert.equal(accounting.validInterval(NaN, 5), false);
});

test('normalizes exclusion IDs and matches desktop IDs or original app class', () => {
    assert.equal(accounting.isExcluded('org.mozilla.firefox', 'firefox', [' Firefox.desktop ']), true);
    assert.equal(accounting.isExcluded('org.mozilla.firefox', 'firefox', ['ORG.MOZILLA.FIREFOX']), true);
    assert.equal(accounting.isExcluded('kitty', 'kitty', ['firefox']), false);
    assert.equal(accounting.isExcluded('', '', ['']), false);
});

test('uses Monday-Sunday calendar weeks with zero-filled days and ranked apps', () => {
    const days = {};
    record(days, 'firefox', '2026-10-25', 100);
    record(days, 'firefox', '2026-10-26', 60);
    record(days, 'kitty', '2026-10-27', 120);
    record(days, 'firefox', '2026-11-01', 30);
    record(days, 'kitty', '2026-11-02', 999);
    const report = accounting.summary(days, 'week', date('2026-11-01T18:00:00'));
    assert.equal(report.total, 210);
    assert.equal(report.previousTotal, 100);
    assert.deepEqual(plain(report.apps.map(a => a.id)), ['kitty', 'firefox']);
    assert.equal(report.days.length, 7);
    assert.equal(report.days[0].date, '2026-10-26');
    assert.equal(report.days[6].date, '2026-11-01');
    assert.equal(report.days[6].today, true);
    assert.equal(report.days[2].seconds, 0);
});

test('today compares with yesterday and charts the trailing seven days', () => {
    const days = {};
    record(days, 'kitty', '2026-11-01', 60);
    record(days, 'firefox', '2026-11-02', 90);
    const report = accounting.summary(days, 'today', date('2026-11-02T18:00:00'));
    assert.equal(report.total, 90);
    assert.equal(report.previousTotal, 60);
    assert.equal(report.days[0].date, '2026-10-27');
    assert.equal(report.days[6].date, '2026-11-02');
});

test('last week and its comparison work across a year boundary', () => {
    const days = {};
    record(days, 'firefox', '2026-12-21', 30);
    record(days, 'kitty', '2026-12-28', 60);
    record(days, 'kitty', '2027-01-03', 90);
    record(days, 'firefox', '2027-01-04', 999);
    const report = accounting.summary(days, 'lastWeek', date('2027-01-04T18:00:00'));
    assert.equal(report.total, 150);
    assert.equal(report.previousTotal, 30);
    assert.equal(report.days[0].date, '2026-12-28');
    assert.equal(report.days[6].date, '2027-01-03');
});

test('monthly field contract uses local January boundaries and December comparison', () => {
    const report = accounting.summary({}, 'month', date('2027-01-01T00:00:01'));
    assert.deepEqual(plain(report), {
        total: 0, apps: [], average: 0, elapsedDays: 1, comparisonDays: 1,
        comparisonTotal: 0, previousTotal: 0, change: 0, changePercent: null,
        start: '2027-01-01', end: '2027-01-02',
        comparisonStart: '2026-12-01', comparisonEnd: '2026-12-02',
        monthLabel: 'Januari 2027',
        days: Array.from({ length: 31 }, (_, i) => ({
            date: `2027-01-${String(i + 1).padStart(2, '0')}`,
            label: String(i + 1), seconds: 0, today: i === 0, future: i > 0
        }))
    });
});

test('last month selects all of December across January year rollover', () => {
    const days = {};
    record(days, 'old', '2026-10-31', 999);
    record(days, 'browser', '2026-11-01', 20);
    record(days, 'browser', '2026-11-30', 10);
    record(days, 'editor', '2026-12-01', 60);
    record(days, 'editor', '2026-12-31', 95);
    record(days, 'future', '2027-01-01', 999);
    const report = accounting.summary(days, 'lastMonth', date('2027-01-02T18:00:00'));
    assert.equal(report.monthLabel, 'Desember 2026');
    assert.equal(report.start, '2026-12-01');
    assert.equal(report.end, '2027-01-01');
    assert.equal(report.comparisonStart, '2026-11-01');
    assert.equal(report.comparisonEnd, '2026-12-01');
    assert.equal(report.total, 155);
    assert.equal(report.average, 5);
    assert.equal(report.elapsedDays, 31);
    assert.equal(report.comparisonDays, 30);
    assert.equal(report.comparisonTotal, 60);
    assert.equal(report.previousTotal, 30);
    assert.equal(report.change, 30);
    assert.equal(report.changePercent, 100);
    assert.deepEqual(plain(report.apps), [{ id: 'editor', name: 'editor', icon: '', seconds: 155 }]);
    assert.equal(report.days.length, 31);
    assert.equal(report.days[30].seconds, 95);
    assert.equal(report.days.every(day => !day.today && !day.future), true);
});

test('monthly charts cover every day of 28, 29, 30 and 31 day months', () => {
    const months = [
        ['2027-02', 28, 'Februari'], ['2028-02', 29, 'Februari'],
        ['2027-04', 30, 'April'], ['2027-07', 31, 'Juli']
    ];
    for (const [month, length, label] of months) {
        const first = date(`${month}-01T18:00:00`);
        const next = new Date(first);
        next.setMonth(next.getMonth() + 1);
        const days = {};
        record(days, 'editor', `${month}-${length}`, length);
        for (const [period, now] of [['month', first], ['lastMonth', next.getTime()]]) {
            const report = accounting.summary(days, period, now);
            assert.equal(report.monthLabel, `${label} ${month.slice(0, 4)}`);
            assert.equal(report.days.length, length);
            assert.deepEqual(plain(report.days.map(day => day.date)), Array.from({ length }, (_, i) => `${month}-${String(i + 1).padStart(2, '0')}`));
            assert.deepEqual(plain(report.days.map(day => day.label)), Array.from({ length }, (_, i) => String(i + 1)));
            assert.equal(report.days[length - 1].future, period === 'month');
            assert.equal(report.days[length - 1].seconds, period === 'month' ? 0 : length);
            assert.equal(report.elapsedDays, period === 'month' ? 1 : length);
            assert.equal(report.total, period === 'month' ? 0 : length);
            assert.equal(report.average, period === 'month' ? 0 : 1);
        }
    }
});

test('month to date excludes later days and compares only the first N days', () => {
    const days = {};
    record(days, 'outside', '2027-04-30', 999);
    record(days, 'browser', '2027-05-01', 40);
    record(days, 'browser', '2027-05-10', 20);
    record(days, 'previous-later', '2027-05-11', 999);
    record(days, 'previous-later', '2027-05-31', 999);
    record(days, 'editor', '2027-06-01', 60);
    record(days, 'browser', '2027-06-10', 30);
    record(days, 'future', '2027-06-11', 999);
    record(days, 'future', '2027-06-30', 999);
    record(days, 'outside', '2027-07-01', 999);
    const report = accounting.summary(days, 'month', date('2027-06-10T00:00:01'));
    assert.equal(report.total, 90);
    assert.equal(report.average, 9);
    assert.equal(report.elapsedDays, 10);
    assert.equal(report.comparisonDays, 10);
    assert.equal(report.comparisonTotal, 90);
    assert.equal(report.previousTotal, 60);
    assert.equal(report.change, 30);
    assert.equal(report.changePercent, 50);
    assert.equal(report.start, '2027-06-01');
    assert.equal(report.end, '2027-06-11');
    assert.equal(report.comparisonStart, '2027-05-01');
    assert.equal(report.comparisonEnd, '2027-05-11');
    assert.deepEqual(plain(report.apps.map(app => [app.id, app.seconds])), [['editor', 60], ['browser', 30]]);
    assert.deepEqual(plain(report.days[9]), { date: '2027-06-10', label: '10', seconds: 30, today: true, future: false });
    assert.equal(report.days.slice(10).every(day => day.future && !day.today && day.seconds === 0), true);
    assert.equal(report.days.reduce((sum, day) => sum + day.seconds, 0), report.total);
});

test('31 versus 28 clamps both comparison windows without clamping monthly total', () => {
    const days = {};
    record(days, 'editor', '2027-02-01', 10);
    record(days, 'editor', '2027-02-28', 30);
    record(days, 'editor', '2027-03-01', 20);
    record(days, 'editor', '2027-03-28', 40);
    record(days, 'editor', '2027-03-29', 100);
    record(days, 'editor', '2027-03-30', 100);
    record(days, 'editor', '2027-03-31', 50);
    for (const [period, now] of [
        ['month', '2027-03-31T23:59:59'], ['lastMonth', '2027-04-01T00:00:00']
    ]) {
        const report = accounting.summary(days, period, date(now));
        assert.equal(report.total, 310);
        assert.equal(report.apps[0].seconds, 310);
        assert.equal(report.average, 10);
        assert.equal(report.elapsedDays, 31);
        assert.equal(report.comparisonDays, 28);
        assert.equal(report.comparisonTotal, 60);
        assert.equal(report.previousTotal, 40);
        assert.equal(report.change, 20);
        assert.equal(report.changePercent, 50);
        assert.equal(report.comparisonStart, '2027-02-01');
        assert.equal(report.comparisonEnd, '2027-03-01');
        assert.equal(report.days[30].seconds, 50);
    }
});

test('leap February comparisons include February 29 but not March 30 or 31', () => {
    const days = {};
    record(days, 'editor', '2028-02-29', 20);
    record(days, 'editor', '2028-03-29', 10);
    record(days, 'editor', '2028-03-30', 90);
    const report = accounting.summary(days, 'month', date('2028-03-31T18:00:00'));
    assert.equal(report.comparisonDays, 29);
    assert.equal(report.comparisonTotal, 10);
    assert.equal(report.previousTotal, 20);
    assert.equal(report.change, -10);
    assert.equal(report.changePercent, -50);
    assert.equal(report.total, 100);
    assert.equal(report.comparisonEnd, '2028-03-01');
});

test('monthly averages include zero days and zero previous totals yield null percent', () => {
    const days = {};
    record(days, 'editor', '2027-04-01', 60);
    for (const [period, now, denominator] of [
        ['month', '2027-04-10T18:00:00', 10], ['lastMonth', '2027-05-01T18:00:00', 30]
    ]) {
        const report = accounting.summary(days, period, date(now));
        assert.equal(report.total, 60);
        assert.equal(report.average, 60 / denominator);
        assert.equal(report.elapsedDays, denominator);
        assert.equal(report.previousTotal, 0);
        assert.equal(report.change, 60);
        assert.equal(report.changePercent, null);
        assert.equal(accounting.summary({}, period, date(now)).changePercent, null);
    }
});

test('monthly categorization preserves totals, metadata and version 1 history without mutation', () => {
    const days = {};
    record(days, 'editor', '2027-02-28', 15);
    record(days, 'editor', '2027-03-01', 30);
    record(days, 'browser', '2027-03-10', 20);
    record(days, '__proto__', '2027-03-31', 5);
    record(days, 'outside', '2027-04-01', 999);
    const history = JSON.stringify({ version: 1, days });
    const loaded = accounting.decode(history);
    for (const [period, now] of [['month', '2027-03-31T18:00:00'], ['lastMonth', '2027-04-10T18:00:00']]) {
        const report = accounting.summary(loaded, period, date(now));
        const before = plain(report);
        report.apps.forEach(Object.freeze);
        report.days.forEach(Object.freeze);
        Object.freeze(report.apps);
        Object.freeze(report.days);
        Object.freeze(report);
        const result = accounting.categorize(report, id => id === 'editor' ? 'development' : id === 'browser' ? 'browsing' : 'other');
        const { apps, categories, ...metadata } = plain(result);
        const { apps: originalApps, ...originalMetadata } = before;
        assert.deepEqual(metadata, originalMetadata);
        assert.deepEqual(apps.map(({ category, ...app }) => app), originalApps);
        assert.equal(categories.reduce((sum, category) => sum + category.seconds, 0), report.total);
        assert.deepEqual(categories.map(category => category.seconds), [30, 0, 0, 0, 20, 5]);
        assert.equal(report.total, 55);
        assert.equal(report.comparisonTotal, 50);
        assert.deepEqual(plain(report), before);
    }
    assert.equal(JSON.stringify({ version: 1, days: loaded }), history);
    assert.equal(JSON.stringify({ version: 1, days }), history);
});

test('daily and weekly summaries retain their exact fields and future-week semantics', () => {
    const days = {};
    record(days, 'editor', '2027-06-07', 5);
    record(days, 'editor', '2027-06-08', 10);
    record(days, 'editor', '2027-06-13', 20);
    for (const [period, total, previousTotal] of [['today', 10, 5], ['week', 35, 0], ['lastWeek', 0, 0]]) {
        const report = accounting.summary(days, period, date('2027-06-08T18:00:00'));
        assert.deepEqual(Object.keys(report).sort(), ['apps', 'days', 'previousTotal', 'total']);
        assert.equal(report.total, total);
        assert.equal(report.previousTotal, previousTotal);
        assert.equal(report.days.length, 7);
        for (const day of report.days)
            assert.deepEqual(Object.keys(day).sort(), ['date', 'label', 'seconds', 'today']);
    }
});

test('monthly calendar windows and averages survive spring and fall DST transitions', () => {
    execFileSync(process.execPath, ['-e', `
        const assert = require('node:assert/strict');
        const fs = require('node:fs');
        const vm = require('node:vm');
        const accounting = vm.createContext({});
        vm.runInContext(fs.readFileSync(process.argv[1], 'utf8'), accounting);
        for (const [month, transition, length, hours] of [[3, 8, 31, 23], [11, 1, 30, 25]]) {
            const start = new Date(2026, month - 1, transition);
            const end = accounting.shiftDay(start, 1);
            assert.equal((end - start) / 3600000, hours);
            const days = {};
            accounting.addInterval(days, { id: 'editor', name: 'editor', icon: '' }, start.getTime(), end.getTime(), hours * 3600);
            for (const [period, now, elapsed] of [
                ['month', new Date(2026, month - 1, transition, 23, 59), transition],
                ['lastMonth', new Date(2026, month, 1), length]
            ]) {
                const report = accounting.summary(days, period, now);
                assert.equal(report.total, hours * 3600);
                assert.equal(report.average, hours * 3600 / elapsed);
                assert.equal(report.elapsedDays, elapsed);
                assert.equal(report.comparisonDays, elapsed);
                assert.equal(report.days.length, length);
                assert.equal(report.days[transition - 1].seconds, hours * 3600);
                assert.equal(report.end, accounting.dayKey(period === 'month' ? end : new Date(2026, month, 1)));
                assert.deepEqual(Array.from(report.days, day => day.date), Array.from({ length }, (_, i) => accounting.dayKey(new Date(2026, month - 1, i + 1))));
                assert.equal(report.days.slice(transition).every(day => day.seconds === 0 && day.future === (period === 'month')), true);
            }
        }
    `, path.join(__dirname, '../utils/Usage.js')], { env: { ...process.env, TZ: 'America/New_York' }, timeout: 10000 });
});

test('retention keeps exactly N local dates and removes future records', () => {
    const days = {};
    for (const day of ['2026-10-26', '2026-10-27', '2026-11-02', '2026-11-03'])
        record(days, 'kitty', day, 5);
    assert.equal(accounting.prune(days, date('2026-11-02T18:00:00'), 7), true);
    assert.deepEqual(Object.keys(days), ['2026-10-27', '2026-11-02']);
    assert.equal(accounting.prune(days, date('2026-11-02T18:00:00'), 7), false);
});

test('history survives JSON roundtrips; malformed or unsupported data is rejected', () => {
    const days = {};
    record(days, 'kitty', '2026-11-02', 5);
    assert.deepEqual(plain(accounting.decode(JSON.stringify({ version: 1, days }))), plain(days));
    for (const text of ['oops', '{}', '{"version":2,"days":{}}', '{"version":1,"days":[]}',
        '{"version":1,"days":{"2026-02-30":{}}}', '{"version":1,"days":{"2026-11-02":{"kitty":{"name":"kitty","icon":"","seconds":-1}}}}'])
        assert.throws(() => accounting.decode(text));
});

test('unusual app identifiers do not collide with object prototypes', () => {
    const days = {};
    record(days, '__proto__', '2026-11-02', 5);
    record(days, 'constructor', '2026-11-02', 10);
    const loaded = accounting.decode(JSON.stringify({ version: 1, days }));
    const report = accounting.summary(loaded, 'today', date('2026-11-02T18:00:00'));
    assert.equal(report.total, 15);
    assert.equal(report.apps.length, 2);
});

test('empty summaries and duration formatting', () => {
    const report = accounting.summary({}, 'week', date('2026-11-02T18:00:00'));
    assert.equal(report.total, 0);
    assert.equal(report.days.length, 7);
    assert.equal(report.apps.length, 0);
    assert.equal(accounting.formatDuration(0), '0m');
    assert.equal(accounting.formatDuration(59), '<1m');
    assert.equal(accounting.formatDuration(60), '1m');
    assert.equal(accounting.formatDuration(3660), '1h 01m');
});

test('category definitions are complete, ordered and independent between calls', () => {
    const expected = [
        { id: 'development', label: 'Pengembangan', icon: 'code' },
        { id: 'entertainment', label: 'Hiburan', icon: 'movie' },
        { id: 'communication', label: 'Komunikasi', icon: 'forum' },
        { id: 'productivity', label: 'Produktivitas', icon: 'work' },
        { id: 'browsing', label: 'Browsing', icon: 'language' },
        { id: 'other', label: 'Lainnya', icon: 'apps' }
    ];
    const definitions = accounting.categoryDefinitions();
    assert.deepEqual(plain(definitions), expected);
    definitions[0].label = 'changed';
    definitions.pop();
    assert.deepEqual(plain(accounting.categoryDefinitions()), expected);
});

test('desktop categories map every supported freedesktop token', () => {
    const groups = {
        development: ['Development'],
        communication: ['Chat', 'InstantMessaging', 'Email', 'Telephony', 'VideoConference'],
        browsing: ['WebBrowser'],
        entertainment: ['Game', 'AudioVideo', 'Audio', 'Video', 'Player'],
        productivity: ['Office', 'Graphics', 'Science', 'Education']
    };
    for (const [id, tokens] of Object.entries(groups)) {
        for (const token of tokens) {
            assert.equal(accounting.categoryFor('app', [token]), id, token);
            assert.equal(accounting.categoryFor('app', `;Unknown; ${token} ;;`), id, token);
        }
    }
});

test('category precedence is independent of desktop token order', () => {
    const tokens = ['Chat', 'WebBrowser', 'Development', 'Game', 'Office'];
    const expected = ['communication', 'browsing', 'development', 'entertainment', 'productivity'];
    for (let i = 0; i < tokens.length; i++) {
        const remaining = tokens.slice(i);
        assert.equal(accounting.categoryFor('app', remaining), expected[i]);
        assert.equal(accounting.categoryFor('app', remaining.reverse().join(';')), expected[i]);
    }
});

test('valid overrides win and app IDs normalize case, whitespace and desktop suffix', () => {
    const overrides = Object.freeze({ ' Org.Example.App.DESKTOP ': 'productivity' });
    for (const id of ['org.example.app', 'ORG.EXAMPLE.APP.desktop', ' org.example.app '])
        assert.equal(accounting.categoryFor(id, 'Chat;Development;', overrides), 'productivity');
    for (const category of accounting.categoryDefinitions())
        assert.equal(accounting.categoryFor('app.desktop', ['Chat'], { APP: category.id }), category.id);
    for (const invalid of ['unknown', 'constructor', '__proto__', 'Development', '', null, undefined, 1, {}, []])
        assert.equal(accounting.categoryFor('app', ['Development'], { app: invalid }), 'development');
});

test('unknown and malformed category inputs safely fall back', () => {
    const malformed = [null, undefined, 42, true, {}, { toString: null }, ['Unknown', null, {}, 42]];
    for (const value of malformed) {
        assert.equal(accounting.categoryFor(value, value, value), 'other');
        assert.equal(accounting.categoryFor('app', 'WebBrowser;', value), 'browsing');
    }
    assert.equal(accounting.categoryFor('', 'Office', { '': 'development' }), 'productivity');
    assert.equal(accounting.categoryFor('app', ['Unknown', null, {}, 'Email']), 'communication');
    assert.equal(accounting.categoryFor('app', 'Unknown;Utility;'), 'other');
});

test('category overrides use own keys and safely handle prototype identifiers', () => {
    const inherited = Object.create({ app: 'development', constructor: 'development' });
    assert.equal(accounting.categoryFor('app', ['Office'], inherited), 'productivity');
    for (const id of ['__proto__', 'constructor', 'toString']) {
        assert.equal(accounting.categoryFor(id, [], {}), 'other');
        const overrides = Object.create(null);
        overrides[`${id.toUpperCase()}.desktop`] = 'communication';
        assert.equal(accounting.categoryFor(id, [], overrides), 'communication');
    }
});

test('categoryOverride returns only valid own overrides for normalized IDs', () => {
    const overrides = Object.freeze({ ' APP.DESKTOP ': 'development', unrelated: 'browsing' });
    assert.equal(accounting.categoryOverride('app', overrides), 'development');
    assert.equal(accounting.categoryOverride(' App.desktop ', overrides), 'development');
    assert.equal(accounting.categoryOverride('missing', overrides), '');
    assert.equal(accounting.categoryOverride('app', Object.create({ app: 'development' })), '');
    for (const invalid of [null, undefined, 1, {}, [], 'unknown', '__proto__', 'constructor', 'Development', ''])
        assert.equal(accounting.categoryOverride('app', { app: invalid }), '');
    for (const invalid of [null, undefined, 1, {}, [], '', ' ', '.desktop'])
        assert.equal(accounting.categoryOverride(invalid, overrides), '');
    for (const invalid of [null, undefined, 1, [], 'app'])
        assert.equal(accounting.categoryOverride('app', invalid), '');
});

test('override setter canonicalizes IDs and removes all equivalent keys without mutation', () => {
    const overrides = Object.freeze({
        APP: 'development', ' App.desktop ': 'entertainment', app: 'invalid',
        unrelated: 'browsing', unknown: 'preserved'
    });
    for (const category of accounting.categoryDefinitions()) {
        const result = accounting.withCategoryOverride(' APP.DESKTOP ', category.id, overrides);
        assert.notEqual(result, overrides);
        assert.deepEqual(plain(result), { unrelated: 'browsing', unknown: 'preserved', app: category.id });
        assert.equal(accounting.categoryOverride('app.desktop', result), category.id);
        assert.equal(accounting.categoryFor('app', 'Chat;', result), category.id);
    }
    assert.deepEqual(overrides, {
        APP: 'development', ' App.desktop ': 'entertainment', app: 'invalid',
        unrelated: 'browsing', unknown: 'preserved'
    });
});

test('empty category resets all equivalent overrides and restores automatic classification', () => {
    const overrides = Object.freeze({ APP: 'development', 'app.desktop': 'browsing', keep: 'other' });
    const result = accounting.withCategoryOverride(' App.Desktop ', '', overrides);
    assert.deepEqual(plain(result), { keep: 'other' });
    assert.equal(accounting.categoryOverride('app', result), '');
    assert.equal(accounting.categoryFor('app', 'Chat;', result), 'communication');
    assert.deepEqual(plain(accounting.withCategoryOverride('missing', '', overrides)), overrides);
    assert.equal(Object.keys(overrides).length, 3);
});

test('invalid override edits return independent unchanged copies', () => {
    const overrides = Object.freeze({ 'APP.desktop': 'development', keep: 'other' });
    for (const category of [undefined, null, 1, {}, [], 'unknown', '__proto__', 'constructor', 'Development', ' ']) {
        const result = accounting.withCategoryOverride('app', category, overrides);
        assert.notEqual(result, overrides);
        assert.deepEqual(plain(result), overrides);
    }
    for (const id of ['', ' ', '.desktop', null, undefined, 1, {}, []]) {
        for (const category of ['browsing', '']) {
            const result = accounting.withCategoryOverride(id, category, overrides);
            assert.notEqual(result, overrides);
            assert.deepEqual(plain(result), overrides);
        }
    }
    for (const input of [null, undefined, 1, [], 'invalid']) {
        assert.deepEqual(plain(accounting.withCategoryOverride('app', 'development', input)), { app: 'development' });
        assert.deepEqual(plain(accounting.withCategoryOverride('', '', input)), {});
    }
});

test('override edits preserve own prototype names without copying inherited entries', () => {
    const overrides = Object.create({ inherited: 'development' });
    for (const id of ['__proto__', 'constructor', 'toString']) {
        Object.defineProperty(overrides, id, { value: 'entertainment', enumerable: true });
        Object.defineProperty(overrides, `${id.toUpperCase()}.desktop`, { value: 'development', enumerable: true });
    }
    Object.freeze(overrides);
    const before = plain(overrides);
    for (const id of ['__proto__', 'constructor', 'toString']) {
        const canonical = id.toLowerCase();
        const result = accounting.withCategoryOverride(` ${id}.DESKTOP `, 'communication', overrides);
        assert.equal(Object.hasOwn(result, canonical), true);
        assert.equal(result[canonical], 'communication');
        assert.equal(Object.hasOwn(result, `${id.toUpperCase()}.desktop`), false);
        assert.equal(Object.hasOwn(result, 'inherited'), false);
        assert.equal(accounting.categoryOverride(id, result), 'communication');
        assert.equal(Object.getPrototypeOf(result), Object.getPrototypeOf(accounting.withCategoryOverride('', '', {})));
        const reset = accounting.withCategoryOverride(id, '', result);
        assert.equal(Object.hasOwn(reset, canonical), false);
        assert.equal(accounting.categoryOverride(id, reset), '');
        for (const other of ['__proto__', 'constructor', 'toString'].filter(other => other !== id))
            assert.equal(Object.hasOwn(reset, other), true);
        const unchanged = accounting.withCategoryOverride(id, 'invalid', overrides);
        assert.deepEqual(plain(unchanged), before);
        assert.equal(Object.hasOwn(unchanged, '__proto__'), true);
    }
    assert.deepEqual(plain(overrides), before);
});

test('media matching uses exact normalized raw or desktop IDs', () => {
    assert.equal(accounting.mediaMatches(' VLC.DESKTOP ', '', 'vlc', ''), true);
    assert.equal(accounting.mediaMatches('unrelated', 'org.Video.Player', 'ORG.VIDEO.PLAYER.desktop', ''), true);
    assert.equal(accounting.mediaMatches('__proto__', '', '__PROTO__.desktop', ''), true);
    for (const [raw, desktop, player] of [
        ['vlc-helper', '', 'vlc'], ['vlc', '', 'vlc-helper'],
        ['org.vlc', 'org.vlc.Player', 'vlc'], ['', 'firefox-nightly', 'firefox'],
        ['org.mpris.MediaPlayer2.vlc', '', 'vlc']
    ])
        assert.equal(accounting.mediaMatches(raw, desktop, player, ''), false);
});

test('media matching accepts a resolved canonical desktop entry only with a player desktop ID', () => {
    assert.equal(accounting.mediaMatches('org.Video.Player', '', 'player-alias.desktop', 'ORG.VIDEO.PLAYER.desktop'), true);
    assert.equal(accounting.mediaMatches('window-class', 'org.Video.Player', 'player-alias', 'org.Video.Player'), true);
    assert.equal(accounting.mediaMatches('player-alias', '', 'player-alias', 'org.Video.Player'), true);
    assert.equal(accounting.mediaMatches('org.Video.Player-helper', '', 'player-alias', 'org.Video.Player'), false);
    for (const missing of [undefined, null, '', ' ', '.desktop', 1, {}, []]) {
        assert.equal(accounting.mediaMatches('vlc', 'vlc', missing, 'vlc'), false);
        assert.equal(accounting.mediaMatches(missing, missing, 'vlc', missing), false);
    }
    assert.equal(accounting.mediaMatches('', '', '', ''), false);
    assert.equal(accounting.mediaMatches('', '', 'vlc', ''), false);
});

test('categorization conserves app totals without mutating reports or version 1 history', () => {
    const days = {};
    record(days, 'editor', '2026-11-02', 30.5);
    record(days, 'terminal', '2026-11-02', 15.25);
    record(days, 'browser', '2026-11-02', 20);
    record(days, '__proto__', '2026-11-02', 4.25);
    const history = JSON.stringify({ version: 1, days });
    const loaded = accounting.decode(history);
    const report = accounting.summary(loaded, 'today', date('2026-11-02T18:00:00'));
    const original = plain(report);
    report.apps.forEach(Object.freeze);
    Object.freeze(report.apps);
    Object.freeze(report);
    const calls = [];
    const result = accounting.categorize(report, id => {
        calls.push(id);
        return id === 'editor' || id === 'terminal' ? 'development'
            : id === 'browser' ? 'browsing' : '__proto__';
    });
    assert.deepEqual(calls, original.apps.map(app => app.id));
    assert.notEqual(result, report);
    assert.notEqual(result.apps, report.apps);
    result.apps.forEach((app, i) => {
        assert.notEqual(app, report.apps[i]);
        const { category, ...rest } = app;
        assert.deepEqual(rest, original.apps[i]);
        assert.equal(category, app.id === 'browser' ? 'browsing' : app.id === '__proto__' ? 'other' : 'development');
    });
    assert.equal(result.total, report.total);
    assert.equal(result.previousTotal, report.previousTotal);
    assert.deepEqual(plain(result.days), original.days);
    assert.deepEqual(plain(result.categories), plain(accounting.categoryDefinitions()).map(category => ({
        ...category,
        seconds: category.id === 'development' ? 45.75 : category.id === 'browsing' ? 20 : category.id === 'other' ? 4.25 : 0
    })));
    assert.equal(result.categories.reduce((sum, category) => sum + category.seconds, 0), result.total);
    assert.deepEqual(plain(report), original);
    assert.equal(JSON.stringify({ version: 1, days: loaded }), history);
    assert.equal(JSON.stringify({ version: 1, days }), history);
    assert.deepEqual(Object.keys(loaded['2026-11-02'].editor).sort(), ['icon', 'name', 'seconds']);
});

test('empty categorization includes all six zero-filled categories', () => {
    const report = accounting.summary({}, 'today', date('2026-11-02T18:00:00'));
    const result = accounting.categorize(report, () => assert.fail('no apps to resolve'));
    assert.deepEqual(plain(result.apps), []);
    assert.equal(result.total, 0);
    assert.deepEqual(plain(result.categories), plain(accounting.categoryDefinitions()).map(category => ({ ...category, seconds: 0 })));
    assert.equal(Object.hasOwn(report, 'categories'), false);
    for (const input of [null, undefined, {}, { apps: null }, { apps: 'invalid' }]) {
        const empty = accounting.categorize(input);
        assert.equal(empty.apps.length, 0);
        assert.equal(empty.categories.length, 6);
        assert.equal(empty.categories.every(category => category.seconds === 0), true);
    }
});

test('missing or invalid category resolvers fall back to other', () => {
    const report = { total: 5, apps: [{ id: 'app', seconds: 5 }] };
    for (const resolver of [undefined, null, {}, () => null, () => 'constructor', () => 'unknown']) {
        const result = accounting.categorize(report, resolver);
        assert.equal(result.apps[0].category, 'other');
        assert.equal(result.categories.find(category => category.id === 'other').seconds, 5);
    }
});

test('calendar stepping remains correct on daylight-saving transitions', () => {
    for (const day of ['2026-03-08', '2026-11-01']) {
        const start = date(`${day}T00:00:00`);
        const end = accounting.shiftDay(start, 1).getTime();
        const days = {};
        accounting.addInterval(days, app, start, end, (end - start) / 1000);
        assert.deepEqual(Object.keys(days), [day]);
        assert.equal(accounting.summary(days, 'today', start).total, (end - start) / 1000);
    }
});
