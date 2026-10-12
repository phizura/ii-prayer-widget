#!/usr/bin/env fish
# Menghapus ii-prayer-widget. Config di ~/.config/ii-prayer TIDAK dihapus.

set -l repo (realpath (dirname (status --current-filename)))
set -l ii ~/.config/quickshell/ii
if set -q II_DIR
    set ii $II_DIR
end
set -l target $ii/modules/ii/sidebarRight/BottomWidgetGroup.qml
set -l patchfile $repo/patches/bottom-widget-group.patch

if not command -q patch
    echo "[x] Perintah 'patch' tidak ada. Pasang dengan: sudo pacman -S patch"
    exit 1
end

# Urutan penting: cabut entri tab DULU, baru hapus file,
# supaya sidebar tidak merujuk file yang sudah hilang.
if grep -q 'prayer/PrayerWidget.qml' $target
    if patch -R --dry-run -s $target < $patchfile >/dev/null 2>&1
        patch -R -s $target < $patchfile
        echo "[ok] Entri tab Prayer dicabut"
    else
        echo "[x] Patch tidak bisa dibalik otomatis. Hapus manual entri 'prayer' di:"
        echo "    $target"
        echo "    Tidak ada file yang dihapus."
        exit 1
    end
else
    echo "[skip] Entri tab Prayer tidak ditemukan"
end

rm -f $ii/services/PrayerTimes.qml
if test -d $ii/modules/ii/sidebarRight/prayer
    rm -r $ii/modules/ii/sidebarRight/prayer
end
echo "[ok] File widget dihapus. Config tetap ada di ~/.config/ii-prayer"
