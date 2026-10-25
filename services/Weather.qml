pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Cuaca dari wttr.in (butuh internet). Refresh tiap 30 menit.
Singleton {
    id: root

    property bool available: false
    property string location: ""
    property int temp: 0
    property int feelsLike: 0
    property int humidity: 0
    property int wind: 0
    property string windDir: ""
    property int uv: 0
    property string description: ""
    // "sun", "partly", "cloud", "fog", "rain", "storm", "snow"
    property string kind: "cloud"
    property string sunrise: ""
    property string sunset: ""
    // [{ date, min, max, kind }]; wttr.in hanya memberi 3 hari
    property var forecast: []

    function kindOf(code: int): string {
        if (code === 113)
            return "sun";
        if (code === 116)
            return "partly";
        if ([119, 122].includes(code))
            return "cloud";
        if ([143, 248, 260].includes(code))
            return "fog";
        if ([200, 386, 389, 392, 395].includes(code))
            return "storm";
        if ([179, 182, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(code))
            return "snow";
        return "rain";
    }

    // "05:38 AM" -> "05:38"
    function to24(s: string): string {
        const m = s.match(/(\d+):(\d+)\s*(AM|PM)/i);
        if (!m)
            return s;
        let h = Number(m[1]) % 12;
        if (m[3].toUpperCase() === "PM")
            h += 12;
        return `${String(h).padStart(2, "0")}:${m[2]}`;
    }

    function refresh(): void {
        proc.running = true;
    }

    Process {
        id: proc

        command: ["curl", "-sf", "--max-time", "15", `https://wttr.in/${encodeURIComponent(Config.weatherLocation)}?format=j1&lang=id`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const c = d.current_condition[0];
                    root.temp = Number(c.temp_C);
                    root.feelsLike = Number(c.FeelsLikeC);
                    root.humidity = Number(c.humidity);
                    root.wind = Number(c.windspeedKmph);
                    root.windDir = c.winddir16Point;
                    root.uv = Number(c.uvIndex);
                    root.description = c.lang_id?.[0]?.value ?? c.weatherDesc[0].value;
                    root.kind = root.kindOf(Number(c.weatherCode));
                    root.location = d.nearest_area?.[0]?.areaName?.[0]?.value ?? "";
                    const astro = d.weather[0].astronomy[0];
                    root.sunrise = root.to24(astro.sunrise);
                    root.sunset = root.to24(astro.sunset);
                    root.forecast = d.weather.map(w => ({
                                date: w.date,
                                min: Number(w.mintempC),
                                max: Number(w.maxtempC),
                                kind: root.kindOf(Number((w.hourly[4] ?? w.hourly[0]).weatherCode))
                            }));
                    root.available = true;
                } catch (e) {
                    root.available = false;
                }
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Connections {
        target: Config

        function onWeatherLocationChanged(): void {
            root.refresh();
        }
    }
}
