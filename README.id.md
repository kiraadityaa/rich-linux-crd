# RICH Linux CRD — Ringkasan Bahasa Indonesia

[English](README.md) | **Bahasa Indonesia**

> Ubuntu 24.04 di GitHub Actions + Chrome Remote Desktop. Pilih desktop **Cinnamon** yang ringan atau **GNOME** yang stabil, lalu remote dari mana saja dengan PIN.

<p align="center">
  <img src="assets/rich-linux-crd-banner.svg" alt="Banner RICH Linux CRD" width="820" />
</p>

Dokumen utama (lengkap, dalam Bahasa Inggris): [README.md](README.md). Halaman ini ringkasannya dalam Bahasa Indonesia.

**Fitur cepat:**
- **Setup 3 langkah, 5 menit** — tanpa SSH, tanpa port forwarding, tanpa firewall. Cukup salin perintah CRD, jalankan workflow, konek dari browser.
- **Tema Catppuccin + Ikon Zafiro** — workflow Cinnamon otomatis memasang tema Catppuccin-B-LB-Dark dan ikon Zafiro-Nord-Black.
- **Resolusi otomatis 1600x1200** — xrandr auto-detect tampilan dan menerapkan resolusi optimal.
- **Audio streaming** — Chrome Remote Desktop menyiarkan audio dari sesi remote ke browser secara otomatis.
- **Instalasi senyap** — hook needrestart dinonaktifkan, jadi tidak ada log `Scanning processes...` dan tidak ada restart layanan otomatis saat install/upgrade (mencegah sesi CRD putus).

![Arsitektur: input pengguna mengalir melalui instalasi GitHub Actions dan registrasi CRD ke koneksi browser](assets/architecture.svg)

---

## Fitur Unggulan

### Setup Mudah — 3 Langkah, 5 Menit

Tanpa SSH keys, tanpa port forwarding, tanpa firewall. Cukup salin perintah CRD dari halaman Google, tempel ke workflow GitHub Actions, dan konek dari browser. Seluruh stack — desktop environment, browser, code editor, dan remote access — terinstal otomatis.

### Pengalaman Remote yang Mulus

Sesi Cinnamon dan GNOME dikonfigurasi untuk operasi headless:

- **Direct exec** — session file melewati wrapper LightDM/Xsession yang menyebabkan crash "Oh no! Something has gone wrong"
- **Mesa software rendering** (`LIBGL_ALWAYS_SOFTWARE=1`) memastikan desktop render dengan benar di GitHub Actions runner tanpa GPU fisik
- **Screensaver dan lock dinonaktifkan** — sesi tetap hidup dan responsif, tidak pernah timeout atau mengunci Anda keluar
- **Resolusi otomatis 1600x1200** (Cinnamon) — xrandr auto-detect tampilan dan menerapkan resolusi optimal

### Audio Streaming

Chrome Remote Desktop menyiarkan audio dari sesi remote ke browser secara otomatis. Tidak perlu konfigurasi PulseAudio atau PipeWire — Cinnamon dan GNOME keduanya menggunakan audio stack Ubuntu default, dan CRD menangani sisanya. Putar musik, tonton video, atau ikut video call — audio langsung jalan.

### Tema Catppuccin & Ikon Zafiro (Cinnamon)

Workflow Cinnamon hadir dengan tampilan premium langsung dari awal:

- **Catppuccin-B-LB-Dark** — tema GTK/Cinnamon gelap dengan elemen UI yang halus dan rounded
- **Zafiro-Nord-Black** — tema ikon flat minimalis berdasarkan palet warna Nord
- **Wallpaper Catppuccin Black Unicat** — sudah di-set sebagai background desktop
- Tema dan ikon diterapkan otomatis via dconf, dengan autostart fallback agar persist lintas sesi

### Dev Tools Bawaan

| Tool | Kegunaan |
|---|---|
| Google Chrome | Browser lengkap dengan ekstensi, profil, dan DevTools |
| VS Code | Code editor dengan terminal, ekstensi, dan remote development |
| OpenCode CLI + Desktop | Asisten coding bertenaga AI |

Semua tool sudah terinstal dan tersedia dari menu aplikasi (Cinnamon) atau shortcut desktop (GNOME).

### Upgrade Anti-Putus

Menjalankan `sudo apt upgrade` di dalam sesi CRD memutus koneksi (karena me-restart service CRD/GNOME/systemd). Helper [`safe-upgrade`](scripts/safe-upgrade.sh) menyelesaikan ini:

- Menahan paket kritis (CRD, desktop shell, systemd, kernel)
- Mengupgrade sisanya dengan aman
- MOTD warning di kedua workflow (plus shortcut **Safe Upgrade** di GNOME) mencegah `apt upgrade` yang tidak sengaja

---

## Mulai Cepat (5 menit)

### 1. Ambil perintah host CRD

1. Buka <https://remotedesktop.google.com/headless> di browser yang login akun Google.
2. Klik **Begin** → **Next** → **Authorize**.
3. Salin **perintah Debian Linux** yang muncul (diawali `DISPLAY= ... start-host ...`). Jangan dijalankan di lokal — cukup salin.

### 2. Jalankan workflow

1. Buka tab **Actions** di repo ini.
2. Pilih workflow:
   - **RICH LINUX (Cinnamon + Chrome Remote Desktop)** → file `.github/workflows/cinnamon.yml`
   - **RICH LINUX (GNOME + Chrome Remote Desktop)** → file `.github/workflows/gnome.yml`
3. Klik **Run workflow**, tempel perintah CRD ke field `crd_host_command`, klik **Run**.
4. Tunggu sekitar 5–10 menit sampai log menampilkan `CHROME REMOTE DESKTOP READY`.

### 3. Connect

1. Buka <https://remotedesktop.google.com/access>.
2. Klik perangkatmu → masukkan PIN:
   - Default: `123456`
   - Custom: buat secret repo bernama `CRD_PIN` (minimal 6 digit) sebelum menjalankan workflow.

---

## Cinnamon vs GNOME

|  | Cinnamon (`cinnamon.yml`) | GNOME (`gnome.yml`) |
|---|---|---|
| Tampilan | Klasik ala Linux Mint | Modern ala Ubuntu |
| Ukuran install | Sekitar 1 GB | Sekitar 2 GB |
| Tema | Catppuccin-B-LB-Dark + ikon Zafiro-Nord-Black (otomatis) | Adwaita default |
| Resolusi | Otomatis 1600x1200 via xrandr | Default CRD |
| Sesi CRD | `exec /usr/bin/cinnamon-session --session cinnamon` + `LIBGL_ALWAYS_SOFTWARE=1` | `exec /usr/bin/gnome-session --session=ubuntu` + `LIBGL_ALWAYS_SOFTWARE=1` |
| Display manager | Tidak dipakai (headless) | Tidak dipakai (headless) |
| Shortcut desktop | Tidak ada (desktop bersih) | Antigravity, VS Code, OpenCode, Safe Upgrade |
| Screensaver, lock, suspend | Dinonaktifkan | Dinonaktifkan |
| Wallpaper | Catppuccin Black Unicat (via `org.cinnamon.desktop.background`) | Catppuccin Black Unicat (via `org.gnome.desktop.background`) |
| Upgrade | Full upgrade di build-time + `safe-upgrade` di sesi | Full upgrade di build-time + `safe-upgrade` di sesi |
| Cocok untuk | Tampilan ala Mint, ukuran lebih ringan, tema premium | Stabilitas maksimal |

---

## Penting: jangan `apt upgrade` polos di dalam sesi

Gejala: setelah `sudo apt update && sudo apt upgrade -y`, sesi tiba-tiba putus dan tidak bisa konek ulang.

Penyebab: upgrade ikut menaikkan `chrome-remote-desktop` / `gnome-shell` / `mutter` / `gdm3` / `systemd` / `dbus`, lalu service-nya di-restart sehingga sesi X mati.

> [!WARNING]
> Jangan jalankan `sudo apt upgrade -y` polos di dalam sesi CRD. Pakai helper `safe-upgrade`.

| Kebutuhan | Cara |
|---|---|
| Upgrade harian yang aman (di terminal CRD) | `safe-upgrade` |
| Cek dulu tanpa mengubah apa pun | `safe-upgrade --check` |
| Upgrade CRD/Chrome/desktop juga (SESI AKAN PUTUS) | `safe-upgrade --allow-crd-restart` / `safe-upgrade --include-desktop` |
| Dapat upgrade kritis tanpa putus | Re-run workflow Actions (sudah full `upgrade` di build-time) |

Implementasi: [`scripts/safe-upgrade.sh`](scripts/safe-upgrade.sh).

---

## Struktur repo

```
rich-linux-crd/
├── .github/workflows/       # cinnamon.yml, gnome.yml
├── assets/
│   ├── architecture.svg     # Diagram arsitektur di README
│   ├── cinnamon-theme.zip   # Tema Catppuccin + ikon Zafiro (otomatis diinstal oleh workflow Cinnamon)
│   └── rich-linux-crd-banner.svg
├── scripts/                 # safe-upgrade.sh
├── README.md                # Dokumen utama (Inggris)
├── README.id.md             # File ini (Indonesia)
├── LICENSE
└── .gitignore
```

---

## Kustomisasi

| Kebutuhan | Cara |
|---|---|
| Ganti PIN | Buat secret repo `CRD_PIN` (Settings → Secrets → Actions), minimal 6 digit |
| Ganti password user `runner` | Edit baris `echo "runner:...` di workflow. Default password "root"|
| Tambah aplikasi | Tambah step `apt-get install` baru sebelum step CRD (needrestart sudah dinonaktifkan, jadi tetap senyap) |
| Ganti wallpaper | Edit URL download di step **Set Wallpaper** di workflow |
| Ganti resolusi tampilan | Edit config dummy Xorg dan perintah xrandr di step **Configure CRD Cinnamon Session** (STEP 09) di `cinnamon.yml` |
| Ganti tema | Ganti `cinnamon-theme.zip` di `assets/` dengan tema Anda sendiri (harus berisi direktori `themes/` dan `icons/`) |
| Perpanjang durasi | Edit `sleep 21600` di step **Keep Alive** (maks 6 jam karena limit Actions) |

---

## Catatan

- Workflow menggunakan `workflow_dispatch` — hanya berjalan saat Anda menjalankan secara manual.
- Jangan commit perintah CRD ke repo (berisi kode auth sekali pakai). Cukup tempel ke input workflow.
- PIN default `123456` hanya untuk kemudahan. Untuk penggunaan serius, buat `CRD_PIN` custom.
- GitHub Actions free tier punya batas menit bulanan — pantau Settings → Billing.
- Workflow Cinnamon secara otomatis memasang tema Catppuccin dan ikon Zafiro dari `assets/cinnamon-theme.zip` — tidak perlu setup manual.
- Resolusi tampilan di-set ke 1600x1200 via xrandr auto-detection di session file Cinnamon.

---

## Lisensi

MIT — lihat [LICENSE](LICENSE).
