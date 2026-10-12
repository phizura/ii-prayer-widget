pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string configPath: `${Quickshell.env("HOME")}/.config/ii-prayer/config.json`
    readonly property int retryMs: 5 * 60 * 1000

    // --- pengaturan (diisi dari config.json) ---
    property string cityId: ""
    property string timezone: "Asia/Jakarta"

    // --- state ---
    property string status: "loading" // loading | ok | error | noconfig
    property string errorText: ""
    property string locationName: ""
    property string dateLabel: ""
    property var timings: ({})
    property string fetchedFor: ""
    property double lastAttempt: 0

    // --- hasil untuk UI ---
    // array of { label, time, isNext, isPassed }
    property var prayers: []
    property string nextName: ""
    property string nextTime: ""
    property string countdownText: ""

    readonly property string statusMessage: {
        if (status === "noconfig")
            return "Atur cityId di ~/.config/ii-prayer/config.json";
        if (status === "error")
            return "Gagal memuat jadwal: " + errorText;
        return "Memuat jadwal...";
    }

    readonly property var order: [
        { key: "subuh", label: "Subuh" },
        { key: "dzuhur", label: "Dzuhur" },
        { key: "ashar", label: "Ashar" },
        { key: "maghrib", label: "Maghrib" },
        { key: "isya", label: "Isya" }
    ]

    function todayString() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    function timeToDate(hm, dayOffset) {
        const parts = String(hm).split(":");
        const d = new Date();
        d.setDate(d.getDate() + dayOffset);
        d.setHours(parseInt(parts[0]), parseInt(parts[1]), 0, 0);
        return d;
    }

    function applyConfig(text) {
        try {
            const c = JSON.parse(text);
            const id = String(c.cityId || "").trim();
            root.cityId = /^[A-Za-z0-9_-]+$/.test(id) ? id : "";
            root.timezone = c.timezone || "Asia/Jakarta";
        } catch (e) {
            console.error(`[PrayerTimes] config tidak valid: ${e.message}`);
            root.cityId = "";
        }
        root.fetchedFor = "";
        root.lastAttempt = 0;
        if (root.cityId === "") {
            root.status = "noconfig";
            return;
        }
        root.tick();
    }

    function fetchTimes() {
        if (fetcher.running) return;
        root.lastAttempt = Date.now();
        const url = `https://api.myquran.com/v3/sholat/jadwal/${root.cityId}/today?tz=${encodeURIComponent(root.timezone)}`;
        // argv langsung (tanpa shell) supaya aman dari injection
        fetcher.command = ["curl", "-s", "--max-time", "15", url];
        fetcher.running = true;
    }

    function handleResponse(text) {
        try {
            const parsed = JSON.parse(text);
            if (!parsed.status) throw new Error(parsed.message || "response gagal");
            const jadwal = parsed.data.jadwal;
            const day = jadwal[Object.keys(jadwal)[0]];
            root.timings = day;
            root.locationName = parsed.data.kabko || "";
            root.dateLabel = day.tanggal || "";
            root.fetchedFor = root.todayString();
            root.status = "ok";
            root.updateState();
        } catch (e) {
            root.status = "error";
            root.errorText = e.message;
            console.error(`[PrayerTimes] ${e.message}`);
        }
    }

    function updateState() {
        if (!root.timings.subuh) return;
        const now = new Date();
        const list = [];
        let nextIdx = -1;
        for (let i = 0; i < root.order.length; i++) {
            const p = root.order[i];
            const hm = root.timings[p.key];
            const t = root.timeToDate(hm, 0);
            list.push({ label: p.label, time: hm, isNext: false, isPassed: t <= now });
            if (nextIdx === -1 && t > now) nextIdx = i;
        }

        let target;
        let tomorrow = false;
        if (nextIdx === -1) {
            // semua sudah lewat -> Subuh besok (perkiraan: jam Subuh hari ini + 1 hari)
            nextIdx = 0;
            tomorrow = true;
            target = root.timeToDate(root.timings.subuh, 1);
        } else {
            target = root.timeToDate(list[nextIdx].time, 0);
        }
        list[nextIdx].isNext = true;
        list[nextIdx].isPassed = false;

        const mins = Math.floor((target - now) / 60000);
        const h = Math.floor(mins / 60);
        const m = mins % 60;
        let rel = mins < 1 ? "<1m" : (h > 0 ? `${h}j ${m}m` : `${m}m`);

        root.prayers = list;
        root.nextName = list[nextIdx].label;
        root.nextTime = list[nextIdx].time;
        root.countdownText = (tomorrow ? "besok · " : "") + "dalam " + rel;
    }

    function tick() {
        if (root.cityId === "") return;
        const stale = root.fetchedFor !== root.todayString();
        if (stale && (Date.now() - root.lastAttempt > root.retryMs))
            root.fetchTimes();
        root.updateState();
    }

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyConfig(configFile.text())
        onLoadFailed: root.status = "noconfig"
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) {
                    root.status = root.prayers.length > 0 ? "ok" : "error";
                    root.errorText = "tidak ada respons (offline?)";
                    return;
                }
                root.handleResponse(text);
            }
        }
    }

    // Hitung ulang di memori tiap 30 detik; API hanya dipanggil saat tanggal berganti
    Timer {
        running: true
        repeat: true
        interval: 30000
        triggeredOnStart: true
        onTriggered: root.tick()
    }
}
