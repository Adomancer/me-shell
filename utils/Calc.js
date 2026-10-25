.pragma library

// Kalkulator kecil untuk launcher. Hanya angka dan operator, tidak ada kode lain.
function evaluate(expr) {
    const e = expr.trim();
    if (!e || !/^[0-9+\-*/%^.() ]+$/.test(e))
        return null;
    try {
        const r = Function(`"use strict"; return (${e.replace(/\^/g, "**")});`)();
        return typeof r === "number" && isFinite(r) ? Math.round(r * 1e10) / 1e10 : null;
    } catch (err) {
        return null;
    }
}
