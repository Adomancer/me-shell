.pragma library

// Skor kecocokan sederhana: prefix > substring > subsequence. 0 = tidak cocok.
function score(query, text) {
    if (!text)
        return 0;
    query = query.toLowerCase();
    text = text.toLowerCase();
    if (!query)
        return 1;
    if (text.startsWith(query))
        return 1000 - text.length;
    const idx = text.indexOf(query);
    if (idx >= 0)
        return 500 - idx;

    let qi = 0;
    let s = 0;
    let last = -2;
    for (let i = 0; i < text.length && qi < query.length; i++) {
        if (text[i] === query[qi]) {
            s += last === i - 1 ? 3 : 1;
            last = i;
            qi++;
        }
    }
    return qi === query.length ? s : 0;
}
