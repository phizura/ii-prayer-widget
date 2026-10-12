#!/usr/bin/env fish
# Installer ii-prayer-widget.
# Aman dijalankan berulang (idempoten). Tidak memakai sudo.
# Lokasi ii bisa diganti dengan:  set -x II_DIR /path/ke/ii

set -l repo (realpath (dirname (status --current-filename)))
set -l ii ~/.config/quickshell/ii
if set -q II_DIR
    set ii $II_DIR
end
set -l target $ii/modules/ii/sidebarRight/BottomWidgetGroup.qml
set -l patchfile $repo/patches/bottom-widget-group.patch
set -l cfg ~/.config/ii-prayer/config.json

# --- pemeriksaan awal (tidak mengubah apa pun) ---
if not test -d $ii
    echo "[x] Folder ii tidak ditemukan: $ii"
    echo "    Jika lokasinya berbeda: set -x II_DIR /path/ke/ii"
    exit 1
end
if not test -f $target
    echo "[x] File tidak ditemukan: $target"
    echo "    Struktur ii mungkin berbeda dari yang didukung widget ini."
    exit 1
end
if not command -q patch
    echo "[x] Perintah 'patch' tidak ada. Pasang dengan: sudo pacman -S patch"
    exit 1
end
if not test -f $patchfile
    echo "[x] File patch tidak ditemukan: $patchfile"
    exit 1
end

# --- salin file widget (file baru, tidak menimpa file bawaan ii) ---
mkdir -p $ii/modules/ii/sidebarRight/prayer
cp $repo/services/PrayerTimes.qml $ii/services/PrayerTimes.qml
cp $repo/modules/ii/sidebarRight/prayer/PrayerWidget.qml $ii/modules/ii/sidebarRight/prayer/PrayerWidget.qml
echo "[ok] File widget disalin ke $ii"

# --- config per-laptop (tidak ditimpa jika sudah ada) ---
if not test -f $cfg
    mkdir -p (dirname $cfg)
    cp $repo/config.example.json $cfg
    echo "[!] Config dibuat di $cfg - isi cityId Anda (lihat README)."
else
    echo "[skip] Config sudah ada: $cfg"
end

# --- daftarkan tab di BottomWidgetGroup.qml ---
if grep -q 'prayer/PrayerWidget.qml' $target
    echo "[skip] Tab Prayer sudah terdaftar"
else if patch --dry-run -s $target < $patchfile >/dev/null 2>&1
    set -l bak $target.bak-prayer-(date +%F-%H%M%S)
    cp $target $bak
    patch -s $target < $patchfile
    echo "[ok] Tab Prayer didaftarkan (backup: $bak)"
else
    echo "[x] Patch tidak bisa diterapkan otomatis (versi ii mungkin berubah)."
    echo "    Tambahkan manual entri berikut ke array 'tabs' di:"
    echo "    $target"
    echo '        { "type": "prayer", "name": "Prayer", "icon": "mosque", "widget": "prayer/PrayerWidget.qml" },'
    exit 1
end

echo "Selesai. Quickshell biasanya reload otomatis; jika tidak, restart shell."
