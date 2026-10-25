// Jenis cuaca (Weather.kind) ke nama ikon Material Symbols
.pragma library

const icons = {
    sun: "clear_day",
    partly: "partly_cloudy_day",
    cloud: "cloud",
    fog: "foggy",
    rain: "rainy",
    storm: "thunderstorm",
    snow: "weather_snowy"
};

function get(kind) {
    return icons[kind] ?? "cloud";
}
