# AGENTS.md — Panduan Melanjutkan Proyek RICH Linux CRD

File ini adalah instruksi cerdas untuk siapa pun (atau agent AI apa pun) yang ingin melanjutkan
proyek ini, baik dari dalam sesi Chrome Remote Desktop (CRD) yang sudah berjalan, maupun dengan
menjalankan ulang workflow `cinnamon.yml`.

> Baca juga: [README.md](README.md) (dokumen pengguna, EN) dan [README.id.md](README.id.md) (ID).

---

## 1. Orientasi cepat

Proyek ini mengubah GitHub Actions runner (Ubuntu 24.04) menjadi desktop Linux remote yang
diakses via Chrome Remote Desktop. 100% Bash + GitHub Actions YAML. Tidak ada build system,
Makefile, atau unit test — "proses build"-nya adalah eksekusi workflow.

```
rich-linux-crd/
├── .github/workflows/
│   ├── cinnamon.yml   # RICH LINUX (Cinnamon + CRD) — alur penuh 16 step
│   └── gnome.yml      # RICH LINUX (GNOME + CRD) — ~80% sama dengan cinnamon
├── assets/
│   ├── architecture.svg, rich-linux-crd-banner.svg, rich-linux-crd-logo.svg
│   └── cinnamon-theme.zip   # Tema Catppuccin + ikon Zafiro (diekstrak oleh cinnamon.yml)
├── scripts/
│   └── safe-upgrade.sh  # Upgrade aman DI DALAM sesi CRD (pengganti apt upgrade)
├── opencode-setup/
│   └── opencode-skills.md  # Prompt tugas instal Taste Skills v2 + Context7 (berisi API key — JANGAN commit versi apapun dengan key aktif)
├── README.md            # Dokumen utama (EN)
├── README.id.md         # Ringkasan (ID)
├── AGENTS.md            # File ini
├── LICENSE              # MIT
└── .gitignore
```

---

## 2. Melanjutkan dev di dalam sesi CRD yang sudah jalan

Saat Anda `run workflow → connect PIN`, di dalam desktop sudah tersedia:
- **Google Chrome**, **OpenCode CLI + OpenCode Desktop** (kedua workflow)
- **VS Code** (khusus GNOME)
- **`safe-upgrade`** di `/usr/local/bin/safe-upgrade`
- Terminal (`gnome-terminal`), git (bawaan runner)

**Repo TIDAK otomatis ter-clone di dalam sesi CRD.** Workflow hanya menyalin
`scripts/safe-upgrade.sh` dan `assets/cinnamon-theme.zip` dari `$GITHUB_WORKSPACE`. Untuk
melanjutkan pengembangan di dalam CRD:

```bash
mkdir -p ~/dev && cd ~/dev
git clone https://github.com/kiraadityaa/rich-linux-crd.git
cd rich-linux-crd

# Identitas git (nama/email sesuai commit terakhir repo ini)
git config user.name "MasAdityaa.lua"
git config user.email "akunkiraadityaa@gmail.com"
```

**Otentikasi push:** runner tidak punya SSH key bawaan. Dua opsi:
1. HTTPS + PAT: `git remote set-url origin https://<USER>:<TOKEN>@github.com/kiraadityaa/rich-linux-crd.git`
2. Atau `gh auth login` (perlu `gh` diinstaller manual bila belum ada).

---

## 3. Siklus iterasi kerja

1. Edit file (pakai VS Code / OpenCode di dalam CRD, atau CLI).
2. Jalankan validasi cepat sebelum commit:
   - Cek YAML: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/cinnamon.yml'))"`
   - Render heredoc + `bash -n` untuk blok besar ditulis via `run: |` (lihat §8).
3. Commit mengikuti **conventional commits**: `feat:`, `fix:`, `docs:`, `perf:`, `chore:`.
4. Push ke `main` (branch tunggal).
5. Jika perubahan menyentuh workflow → jalankan ulang workflow untuk uji nyata (lihat §4).

---

## 4. Cara pakai `cinnamon.yml`

- **Trigger:** hanya `workflow_dispatch` manual (dari **fork Anda**; GitHub tidak mengizinkan
  trigger Actions di repo milik orang lain).
- **Input wajib:** `crd_host_command` — SELURUH perintah Debian Linux dari
  `https://remotedesktop.google.com/headless` (diawali `DISPLAY= ... start-host ...`). Bersihkan
  CR/LF otomatis; validasi fail-fast: cek kosong + mengandung `start-host`.
- **Secret opsional:** `CRD_PIN` (minimal 6 digit; default `123456`; di-validate `^[0-9]{6,}$`
  dan di-mask via `::add-mask::`).
- **Runner:** `ubuntu-24.04`, `timeout-minutes: 360`, keep-alive `sleep 21600` (6 jam —
  jangan cancel workflow, sesi mati).
- **Cache cepat:** `actions/cache@v4` menyimpan `.deb` apt di `~/apt-archives` (key per-tanggal),
  disinkronkan dari `/var/cache/apt/archives` pada STEP "Sync apt cache". Re-run setelah gagal
  register tidak perlu unduh ulang ~GB.

Alur 16 step (`[STEP XX/17]`): Prepare System → Install Cinnamon → Setup Remote User →
Install Chrome → OpenCode CLI → OpenCode Desktop → Install CRD → **Configure CRD Cinnamon
Session** → Disable Screensaver → Safe-Upgrade Helper → Catppuccin Theme → Set Wallpaper →
Configure CRD PIN → Register CRD (retry 3×, backoff 15/30/45s) → Verify Installation → Keep Alive.

> Catatan: penomoran `XX/17` adalah kosmetik; step nyata berjumlah 16 (Keep Alive tidak
> diberi label STEP).

**Alur koneksi:** buka `https://remotedesktop.google.com/access` → klik perangkat → PIN.
Log mengonfirmasi `CHROME REMOTE DESKTOP READY` saat registrasi sukses.

---

## 5. Fakta runtime kritis (hasil diagnosis — JANGAN dilupakan)

Fakta ini adalah akar berbagai bug yang pernah terjadi; pastikan tidak "dipecahkan ulang" ke arah salah.

1. **CRD selalu start Xorg di display `:20` ke atas** — `FIRST_X_DISPLAY_NUMBER = 20` di
   `/opt/google/chrome-remote-desktop/chrome-remote-desktop`. Jangan pernah memprobe `:0`–`:5`.
2. **CRD mengexport `DISPLAY` + `XAUTHORITY` ke sesi** — sesi file kita cukup pakai `$DISPLAY`.
3. **CRD me-launch Xorg dengan config sendiri:**
   `Xorg :20 ... -configdir /tmp/chrome_remote_desktop_XXXX -config .../none`.
   → Semua config di **`/etc/X11/xorg.conf.d/*` DIABAIKAN** oleh X server CRD.
4. **Sesi file** `/home/runner/.chrome-remote-desktop-session` memakai pola **direct `exec`**
   dengan path absolut (`exec /usr/bin/cinnamon-session --session cinnamon`) + eksplisit
   `DESKTOP_SESSION`, `XDG_*`, `XDG_RUNTIME_DIR`, `LIBGL_ALWAYS_SOFTWARE=1`.
   Tanpa `Xsession`/`lightdm` wrapper → mencegah crash "Oh no! Something has gone wrong".
5. **Dummy driver mengadvertise mode `1600x1200_60`**, BUKAN `1600x1200`. `--mode 1600x1200`
   gagal diam-diam (`|| true`). Fallback: `--newmode "1600x1200_60"` + `--addmode`.
6. **Driver video paket CRD = `dummy`** (`Section "Device" Driver "dummy"` pada config yang
   digenerate CRD), jadi output biasanya bernama `DUMMY0`.
7. **Aktifkan ulang resolusi:** STEP 08 (`Configure CRD Cinnamon Session`) menulis blok xrandr
   di sesi file + autostart `~/.config/autostart/set-resolution.desktop` (fallback ~5s setelah
   Muffin start, karena Muffin bisa me-reset mode).

Perintah verifikasi resolusi di dalam sesi CRD:

```bash
xrandr | grep " connected"     # harap muncul: DUMMY0 connected primary 1600x1200+0+0
```

---

## 6. Aturan keselamatan sesi (critical)

- **JANGAN pernah** `sudo apt upgrade -y` di dalam sesi CRD — meng-upgrade
  `chrome-remote-desktop`/`gnome-shell`/`mutter`/`gdm3`/`systemd`/`dbus` lalu service di-restart
  → sesi X mati & tidak bisa konek ulang (harus re-run workflow).
- Gunakan **`safe-upgrade`** di dalam sesi. Ini men-hold paket kritis otomatis:
  - `--check` (dry-run), `--cleanup` (autoremove), `--include-desktop`,
    `--allow-crd-restart` (keduanya: SESI AKAN PUTUS), `--help`.
  - Rollback tracking: `/var/log/safe-upgrade-pre.log` & `post.log`; summary table; kernel
    reboot check; trap SIGINT/SIGTERM/EXIT melepas hold otomatis.
- **Jangan `apt-get remove cinnamon-screensaver`** — dependensinya `cinnamon` ikut tercopot.
  `disable` saja (autostart `Hidden=true` + dconf no-lock), pattern ada di STEP 09.
- **Upgrade kritis (CRD/desktop/systemd/kernel):** re-run workflow. Catatan: **GNOME** workflow
  menjalankan full `apt-get upgrade` di build-time (SEBELUM sesi jalan, aman); **Cinnamon**
  tidak.
- **needrestart sudah dimatikan** di STEP 01 (hapus hook 99/20needrestart + `$nrconf{restart}='l'`).
  Jangan menghidupkan kembali hook yang me-restart service sembarangan.

---

## 7. Konvensi kode

- **Commit:** conventional commits (`feat:`, `fix:`, `docs:`, `perf:`), satu branch `main`.
- **Komentar:** bilingual diizinkan (EN/ID mix sudah ada di seluruh workflow). Utamakan singkat.
- **Gaya step workflow:**
  - Penanda step: `[STEP XX/17] NAMA`.
  - Var ANSI: `C_CYAN`, `C_GREEN`, `C_YELLOW`, `C_RED`, `C_NC` didefinisikan di awal tiap step.
  - Fail-fast: `command -v <bin> || exit 1`; `test -x /usr/bin/... || exit 1` setelah install.
  - Blok besar via heredoc `<<EOF` (unquoted → `\$`, `\$(...)`, `\${...}` perlu di-escape agar
    hasil file berisi `$`, `$(...)`, `${...}`).
  - Karena YAML `run: |` menghapus indentasi umum (10 spasi), baris penutup heredoc `EOF`
    aman berada di colom 0 setelah stripping.
- **Jangan tambahkan komentar yang tidak perlu**; ikuti pola file yang ada.

---

## 8. Testing & verifikasi (tidak ada unit test)

"Test suite" proyek ini adalah:
1. **Verify Installation** (STEP 15/17) — mengecek binary, sesi file (termasuk
   `grep -q ... Xsession\|lightdm` = harus gagal), dconf, dummy config, service
   `chrome-remote-desktop@runner.service`, user `runner`.
2. **`safe-upgrade --check`** — dry-run aman untuk memvalidasi skrip upgrade.
3. **Validasi heredoc sebelum deploy** (trik):

   ```bash
   # Ekstrak blok sesi file (mis. baris 425-453), strip 10 spasi, jalankan heredoc-nya,
   # lalu bash -n hasilnya.
   sed -n '425,453p' .github/workflows/cinnamon.yml | sed 's/^          //' > /tmp/render.sh
   bash /tmp/render.sh   # menulis /home/runner/.chrome-remote-desktop-session
   bash -n /home/runner/.chrome-remote-desktop-session && echo OK
   ```

4. Validasi YAML: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/cinnamon.yml'))"`.

---

## 9. Catatan keamanan

- **JANGAN commit** perintah `crd_host_command` (mengandung kode auth Google sekali pakai) —
  tempel hanya di input workflow.
- **JANGAN commit API key.** `opencode-setup/opencode-skills.md` mengandung key Context7
  (`ctx7sk-...`) — jangan pernah membawa key aktif ke git. `.gitignore` sudah mengecualikan
  `.opencode/` (bisa berisi key).
- `CRD_PIN` via secret di-mask (`::add-mask::`); jangan cetak PIN ke log.
- Password user `runner:root` sengaja di-hardcode (untuk login lokal di sesi CRD) — tercantum
  juga di README; jangan perkuat tanpa menyinkronkan dokumen.

---

## 10. Referensi debugging (di dalam sesi / runner)

```bash
# Sesi & display
xrandr | grep " connected"
ls -l /home/runner/.chrome-remote-desktop-session
cat /home/runner/.chrome-remote-desktop-session

# Service CRD
systemctl status chrome-remote-desktop@runner.service --no-pager
journalctl -u chrome-remote-desktop@runner.service --no-pager -n 50

# Log CRD user (untuk pelaporan bug, ikuti template Contributing di README)
ls -l /home/runner/.chrome-remote-desktop-*.log

# Paket
dpkg -l | grep -iE "chrome-remote|cinnamon|gnome-shell"
apt-mark showhold
```

---

**Ringkasan mental model:** CRD = Xorg `:20` (dummy driver) + sesi file direct-exec  +
software rendering; jangan upgrade paket kritis dari dalam sesi; resolusi = mode
`1600x1200_60` via `$DISPLAY`; re-run workflow = cara utama deploy & dapatkan upgrade kritis.