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

function categoryDefinitions() {
    return [
        { id: "development", label: "Pengembangan", icon: "code" },
        { id: "entertainment", label: "Hiburan", icon: "movie" },
        { id: "communication", label: "Komunikasi", icon: "forum" },
        { id: "productivity", label: "Produktivitas", icon: "work" },
        { id: "browsing", label: "Browsing", icon: "language" },
        { id: "other", label: "Lainnya", icon: "apps" }
    ];
}

function categoryOverride(appId, overrides) {
    const definitions = categoryDefinitions();
    const id = typeof appId === "string" ? normalizeId(appId) : "";
    if (id && overrides && typeof overrides === "object" && !Array.isArray(overrides)) {
        for (const key of Object.keys(overrides)) {
            if (normalizeId(key) === id && definitions.some(category => category.id === overrides[key]))
                return overrides[key];
        }
    }
    return "";
}

function withCategoryOverride(appId, categoryId, overrides) {
    const result = {};
    const id = typeof appId === "string" ? normalizeId(appId) : "";
    const valid = categoryId === "" || categoryDefinitions().some(category => category.id === categoryId);
    if (overrides && typeof overrides === "object" && !Array.isArray(overrides)) {
        for (const key of Object.keys(overrides)) {
            if (id && valid && normalizeId(key) === id)
                continue;
            Object.defineProperty(result, key, {
                value: overrides[key], writable: true, enumerable: true, configurable: true
            });
        }
    }
    if (id && valid && categoryId !== "") {
        Object.defineProperty(result, id, {
            value: categoryId, writable: true, enumerable: true, configurable: true
        });
    }
    return result;
}

function categoryFor(appId, desktopCategories, overrides) {
    const override = categoryOverride(appId, overrides);
    if (override)
        return override;
    const categories = (typeof desktopCategories === "string" ? desktopCategories.split(";")
        : Array.isArray(desktopCategories) ? desktopCategories : [])
        .filter(category => typeof category === "string").map(category => category.trim());
    // Desktop entries can contain several categories; priority is independent of their order.
    const priorities = [
        { id: "communication", matches: ["Chat", "InstantMessaging", "Email", "Telephony", "VideoConference"] },
        { id: "browsing", matches: ["WebBrowser"] },
        { id: "development", matches: ["Development", "TerminalEmulator", "TextEditor", "IDE"] },
        { id: "entertainment", matches: ["Game", "AudioVideo", "Audio", "Video", "Player"] },
        { id: "productivity", matches: ["Office", "Graphics", "Science", "Education"] }
    ];
    for (const category of priorities) {
        if (category.matches.some(value => categories.indexOf(value) !== -1))
            return category.id;
    }
    return "other";
}

function categorize(report, resolver) {
    const categories = categoryDefinitions().map(category => Object.assign({}, category, { seconds: 0 }));
    const source = report && typeof report === "object" && !Array.isArray(report) ? report : {};
    const apps = (Array.isArray(source.apps) ? source.apps : [])
        .filter(app => app && typeof app === "object" && !Array.isArray(app))
        .map(app => {
            const resolved = typeof resolver === "function" ? resolver(app.id) : "other";
            const category = categories.find(value => value.id === resolved) || categories[categories.length - 1];
            if (Number.isFinite(app.seconds))
                category.seconds += app.seconds;
            return Object.assign({}, app, { category: category.id });
        });
    return Object.assign({}, source, { apps: apps, categories: categories });
}

function mediaMatches(rawId, desktopId, playerDesktopId, resolvedPlayerId) {
    if (typeof playerDesktopId !== "string" || !normalizeId(playerDesktopId))
        return false;
    const apps = [rawId, desktopId].filter(id => typeof id === "string").map(normalizeId).filter(id => id !== "");
    const players = [playerDesktopId, resolvedPlayerId].filter(id => typeof id === "string").map(normalizeId).filter(id => id !== "");
    return apps.some(id => players.indexOf(id) !== -1);
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
        const previous = Object.prototype.hasOwnProperty.call(apps, app.id) ? apps[app.id] : { seconds: 0 };
        Object.defineProperty(apps, app.id, {
            value: { name: app.name || previous.name || app.id, icon: app.icon || previous.icon || "", seconds: previous.seconds + seconds * (boundary - cursor) / (end - start) },
            writable: true, enumerable: true, configurable: true
        });
        cursor = boundary;
    }
}

function prune(days, now, retention) {
    const cutoff = dayKey(shiftDay(now, 1 - retention));
    let changed = false;
    for (const key of Object.keys(days)) {
        if (key < cutoff) {
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
    if (period === "month" || period === "lastMonth") {
        const start = new Date(today.getFullYear(), today.getMonth() - (period === "lastMonth" ? 1 : 0), 1);
        const nextMonth = new Date(start.getFullYear(), start.getMonth() + 1, 1);
        const length = new Date(start.getFullYear(), start.getMonth() + 1, 0).getDate();
        const elapsedDays = period === "month" ? today.getDate() : length;
        const end = period === "month" ? shiftDay(today, 1) : nextMonth;
        const previousStart = new Date(start.getFullYear(), start.getMonth() - 1, 1);
        const previousLength = new Date(start.getFullYear(), start.getMonth(), 0).getDate();
        const comparisonDays = Math.min(elapsedDays, previousLength);
        const result = totals(days, start, end);
        result.average = result.total / elapsedDays;
        result.elapsedDays = elapsedDays;
        result.comparisonDays = comparisonDays;
        // Clamp both windows: a longer month's total can exceed its fair comparison total.
        result.comparisonTotal = totals(days, start, shiftDay(start, comparisonDays)).total;
        result.previousTotal = totals(days, previousStart, shiftDay(previousStart, comparisonDays)).total;
        result.change = result.comparisonTotal - result.previousTotal;
        result.changePercent = result.previousTotal > 0 ? result.change / result.previousTotal * 100 : null;
        result.start = dayKey(start);
        result.end = dayKey(end);
        result.comparisonStart = dayKey(previousStart);
        result.comparisonEnd = dayKey(shiftDay(previousStart, comparisonDays));
        const months = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
        result.monthLabel = `${months[start.getMonth()]} ${start.getFullYear()}`;
        result.days = [];
        for (let i = 0; i < length; i++) {
            const date = shiftDay(start, i);
            const future = date > today;
            result.days.push({ date: dayKey(date), label: String(i + 1), seconds: future ? 0 : totals(days, date, shiftDay(date, 1)).total, today: dayKey(date) === dayKey(today), future: future });
        }
        return result;
    }
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
