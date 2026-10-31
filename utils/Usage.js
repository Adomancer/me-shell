// Pure calendar/accounting helpers, shared by the QML tracker and Node tests.
function dayKey(value) {
    const d = new Date(value);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function midnight(value) {
    const d = new Date(value);
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function shiftDay(value, offset) {
    const d = midnight(value);
    d.setDate(d.getDate() + offset);
    return d;
}

function normalizeId(id) {
    return String(id || "").trim().toLowerCase().replace(/\.desktop$/, "");
}

function isExcluded(rawId, desktopId, excluded) {
    return excluded.some(id => normalizeId(id) !== "" && (normalizeId(id) === normalizeId(rawId) || normalizeId(id) === normalizeId(desktopId)));
}

// Discard delayed callbacks, suspend gaps, and clock corrections instead of inventing usage.
function validInterval(elapsed, wallElapsed) {
    return Number.isFinite(elapsed) && elapsed > 0 && elapsed <= 15
        && Number.isFinite(wallElapsed) && wallElapsed >= 0 && Math.abs(elapsed - wallElapsed) < 2;
}

function addInterval(days, app, start, end, seconds) {
    if (!app || !app.id || !Number.isFinite(seconds) || seconds <= 0 || end <= start)
        return;
    let cursor = start;
    while (cursor < end) {
        const boundary = Math.min(end, shiftDay(cursor, 1).getTime());
        const key = dayKey(cursor);
        if (!Object.prototype.hasOwnProperty.call(days, key))
            days[key] = {};
        const apps = days[key];
        const previous = Object.prototype.hasOwnProperty.call(apps, app.id) ? apps[app.id].seconds : 0;
        Object.defineProperty(apps, app.id, {
            value: { name: app.name || app.id, icon: app.icon || "", seconds: previous + seconds * (boundary - cursor) / (end - start) },
            writable: true, enumerable: true, configurable: true
        });
        cursor = boundary;
    }
}

function prune(days, now, retention) {
    const cutoff = dayKey(shiftDay(now, 1 - retention));
    const today = dayKey(now);
    let changed = false;
    for (const key of Object.keys(days)) {
        if (key < cutoff || key > today) {
            delete days[key];
            changed = true;
        }
    }
    return changed;
}

function decode(text) {
    const data = JSON.parse(text);
    if (!data || data.version !== 1 || !data.days || typeof data.days !== "object" || Array.isArray(data.days))
        throw new Error("Format riwayat tidak didukung");
    for (const key of Object.keys(data.days)) {
        if (!/^\d{4}-\d{2}-\d{2}$/.test(key) || dayKey(new Date(`${key}T12:00:00`)) !== key)
            throw new Error("Tanggal riwayat tidak valid");
        const apps = data.days[key];
        if (!apps || typeof apps !== "object" || Array.isArray(apps))
            throw new Error("Data aplikasi tidak valid");
        for (const id of Object.keys(apps)) {
            const app = apps[id];
            if (!id || !app || typeof app.name !== "string" || typeof app.icon !== "string" || !Number.isFinite(app.seconds) || app.seconds < 0)
                throw new Error("Durasi aplikasi tidak valid");
        }
    }
    return data.days;
}

function totals(days, start, end) {
    const apps = Object.create(null);
    let total = 0;
    const first = dayKey(start);
    const last = dayKey(end);
    for (const key of Object.keys(days)) {
        if (key < first || key >= last)
            continue;
        for (const id of Object.keys(days[key])) {
            const app = days[key][id];
            if (!apps[id])
                apps[id] = { id: id, name: app.name, icon: app.icon, seconds: 0 };
            apps[id].seconds += app.seconds;
            total += app.seconds;
        }
    }
    return { total: total, apps: Object.keys(apps).map(id => apps[id]).sort((a, b) => b.seconds - a.seconds || a.name.localeCompare(b.name)) };
}

function summary(days, period, now) {
    const today = midnight(now);
    const monday = shiftDay(today, -((today.getDay() + 6) % 7));
    const start = period === "today" ? today : shiftDay(monday, period === "lastWeek" ? -7 : 0);
    const length = period === "today" ? 1 : 7;
    const end = shiftDay(start, length);
    const result = totals(days, start, end);
    result.previousTotal = totals(days, shiftDay(start, -length), start).total;
    const chartStart = period === "today" ? shiftDay(today, -6) : start;
    const labels = ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"];
    result.days = [];
    for (let i = 0; i < 7; i++) {
        const date = shiftDay(chartStart, i);
        result.days.push({ date: dayKey(date), label: labels[date.getDay()], seconds: totals(days, date, shiftDay(date, 1)).total, today: dayKey(date) === dayKey(today) });
    }
    return result;
}

function formatDuration(seconds) {
    const minutes = Math.floor(Math.max(0, seconds || 0) / 60);
    if (seconds > 0 && minutes === 0)
        return "<1m";
    return minutes < 60 ? `${minutes}m` : `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, "0")}m`;
}
