import QtQuick

// Angka dengan tombol < / >, dibatasi from..to.
SettingCycle {
    property int from: 0
    property int to: 10
    property int stepSize: 1
    property string unit: ""

    options: {
        const out = [];
        for (let v = from; v <= to; v += stepSize)
            out.push(v);
        return out;
    }
    wrap: false
    labelWidth: 72
    format: v => `${v}${unit}`
}
