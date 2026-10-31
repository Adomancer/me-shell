const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

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
