.pragma library

// ASCII art cuaca ala wttr.in, 5 baris per jenis (lihat Weather.kind).
var art = {
    sun: [
        "    \\   /    ",
        "     .-.     ",
        "  - (   ) -  ",
        "     `-'     ",
        "    /   \\    "
    ],
    partly: [
        "   \\  /      ",
        " _ /\"\".-.    ",
        "   \\_(   ).  ",
        "   /(___(__) ",
        "             "
    ],
    cloud: [
        "             ",
        "     .--.    ",
        "  .-(    ).  ",
        " (___.__)__) ",
        "             "
    ],
    fog: [
        "             ",
        " _ - _ - _ - ",
        "  _ - _ - _  ",
        " _ - _ - _ - ",
        "             "
    ],
    rain: [
        "     .-.     ",
        "    (   ).   ",
        "   (___(__)  ",
        "    ' ' ' '  ",
        "   ' ' ' '   "
    ],
    storm: [
        "     .-.     ",
        "    (   ).   ",
        "   (___(__)  ",
        "    /_  /_   ",
        "     /   /   "
    ],
    snow: [
        "     .-.     ",
        "    (   ).   ",
        "   (___(__)  ",
        "    *  *  *  ",
        "   *  *  *   "
    ]
};

function get(kind) {
    return (art[kind] || art.cloud).join("\n");
}
