pragma Singleton

import QtQuick
import Quickshell

// The weather from Open-Meteo. Where you are is looked up once from your connection and kept in the settings.
Singleton {
    id: root

    property bool ready: false
    property real temp: 0
    property real high: 0
    property real low: 0
    property int code: 0
    property bool day: true
    readonly property string place: Settings.place
    readonly property string unit: Settings.fahrenheit ? "°F" : "°C"
    readonly property bool fahrenheit: Settings.fahrenheit
    onFahrenheitChanged: refresh()

    readonly property string icon: {
        const c = code;
        if (c === 0) return day ? "clear_day" : "clear_night";
        if (c <= 2) return day ? "partly_cloudy_day" : "partly_cloudy_night";
        if (c === 3) return "cloud";
        if (c <= 48) return "foggy";
        if (c <= 67 || (c >= 80 && c <= 82)) return "rainy";
        if (c <= 77 || c === 85 || c === 86) return "weather_snowy";
        return "thunderstorm";
    }
    readonly property string words: {
        const c = code;
        if (c === 0) return "Clear";
        if (c <= 2) return "Partly cloudy";
        if (c === 3) return "Cloudy";
        if (c <= 48) return "Fog";
        if (c <= 57) return "Drizzle";
        if (c <= 67) return "Rain";
        if (c <= 77) return "Snow";
        if (c <= 82) return "Showers";
        if (c <= 86) return "Snow showers";
        return "Storms";
    }

    function get(url, done) {
        const x = new XMLHttpRequest();
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE) return;
            let d = null;
            try { d = JSON.parse(x.responseText); } catch (e) {}
            done(x.status === 200 ? d : null);
        };
        x.open("GET", url);
        x.send();
    }

    function refresh() {
        if (Settings.lat === 0 && Settings.lon === 0) {
            const use = (lat, lon, city, cc) => {
                Settings.lat = lat;
                Settings.lon = lon;
                Settings.place = city || "";
                Settings.fahrenheit = ["US", "LR", "MM"].includes(cc);
                refresh();
            };
            get("https://ipwho.is/", d => {
                if (d && d.success && d.latitude !== undefined) use(d.latitude, d.longitude, d.city, d.country_code);
                else get("https://ipapi.co/json/", e => {
                    if (e && e.latitude !== undefined) use(e.latitude, e.longitude, e.city, e.country_code);
                });
            });
            return;
        }
        get("https://api.open-meteo.com/v1/forecast?latitude=" + Settings.lat.toFixed(2) + "&longitude=" + Settings.lon.toFixed(2)
            + (Settings.fahrenheit ? "&temperature_unit=fahrenheit" : "") + "&current=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&timezone=auto", d => {
            if (!d || !d.current) return;
            root.temp = d.current.temperature_2m;
            root.code = d.current.weather_code;
            root.day = d.current.is_day === 1;
            root.high = d.daily.temperature_2m_max[0];
            root.low = d.daily.temperature_2m_min[0];
            root.ready = true;
        });
    }

    Timer {
        interval: 20 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
