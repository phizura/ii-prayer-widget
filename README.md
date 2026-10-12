# ii-prayer-widget

Widget jadwal sholat untuk sidebar kanan [Illogical Impulse](https://github.com/end-4/dots-hyprland) (Quickshell, `ii-qs`).
Menampilkan lima waktu sholat; waktu yang sedang dituju ditebalkan, di-highlight, dan diberi countdown.

Data dari [API MyQuran v3](https://api.myquran.com/v3/doc) (sumber: Kemenag Bimas Islam).
Proyek ini tidak berafiliasi dengan Illogical Impulse maupun MyQuran.

## Kebutuhan
- Illogical Impulse dengan Quickshell (`~/.config/quickshell/ii`)
- `curl` dan `patch` (`sudo pacman -S patch` jika belum ada)
- shell fish untuk menjalankan script instalasi

## Instalasi
```fish
git clone <url-repo-ini> ~/projects/ii-prayer-widget
cd ~/projects/ii-prayer-widget
fish install.fish
```
Script ini menyalin dua file QML baru, membuat config jika belum ada, dan menambahkan satu entri tab
di `BottomWidgetGroup.qml` (backup otomatis dibuat). Aman dijalankan ulang, misalnya setelah update dotfiles ii.

## Konfigurasi
Edit `~/.config/ii-prayer/config.json`:
```json
{ "cityId": "ID_KOTA", "timezone": "Asia/Jakarta" }
```
Cari ID kota:
```fish
curl -s "https://api.myquran.com/v3/sholat/kabkota/cari/<nama-kota>" | jq .
```

## Hapus
```fish
fish uninstall.fish
```

## Catatan
- Jika patch gagal setelah update besar ii, script menampilkan baris yang perlu ditambahkan manual.
- Belum ada: notifikasi, adzan, cache offline.
