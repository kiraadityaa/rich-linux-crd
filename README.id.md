# RICH Linux CRD — Ringkasan Bahasa Indonesia

[English](README.md) | **Bahasa Indonesia**

> Ubuntu 24.04/26.04 di GitHub Actions + Chrome Remote Desktop. Pilih desktop **Cinnamon** yang ringan, **GNOME** yang stabil, atau **XFCE (Beta)** paling cepat — lalu remote dari mana saja dengan PIN.

<p align="center">
  <img src="assets/rich-linux-crd-banner.svg" alt="Banner RICH Linux CRD" width="820" />
</p>

Dokumen utama (lengkap, dalam Bahasa Inggris): [README.md](README.md). Halaman ini ringkasannya dalam Bahasa Indonesia.

**Fitur cepat:**
- **Setup 4 langkah, 5 menit** — fork repo → salin perintah CRD → jalankan workflow → konek dari browser. Tanpa SSH, tanpa port forwarding, tanpa firewall.
- **Tema Catppuccin + Ikon Zafiro** — workflow Cinnamon & XFCE otomatis memasang tema Catppuccin-B-LB-Dark dan ikon Zafiro-Nord-Black (Cinnamon via dconf, XFCE via xfconf).
- **Resolusi otomatis 1600x1200** (semua tiga desktop) — xrandr auto-detect tampilan dan menerapkan resolusi optimal, plus fallback autostart.
- **Virtualisasi KVM** — dukungan `/dev/kvm` (Intel VT-x) dimanfaatkan: QEMU/KVM + libvirt + virt-manager + GNOME Boxes siap pakai; user `runner` sudah masuk grup `kvm` dan `libvirt`.
- **Audio streaming** — Chrome Remote Desktop menyiarkan audio dari sesi remote ke browser secara otomatis.
- **Instalasi senyap** — hook needrestart dinonaktifkan, jadi tidak ada log `Scanning processes...` dan tidak ada restart layanan otomatis saat install/upgrade (mencegah sesi CRD putus).
- **Tanpa snap** — `snapd` + deb transisi `thunderbird`/`firefox` di-purge dan di-hold, sehingga tidak ada hang "retry 30 menit ke snap store" saat install desktop. Tradeoff: `snap install` dan katalog Snap di GNOME Software tidak tersedia.
- **XFCE Beta** — desktop ketiga, paling ringan & cepat (`xfce.yml`), memakai runner image **`ubuntu-26.04` public preview**. Label "beta" memang sengaja: image masih preview. KVM di image ini belum terverifikasi → warn-only.

![Arsitektur: input pengguna mengalir melalui instalasi GitHub Actions dan registrasi CRD ke koneksi browser](assets/architecture.svg)

---

## Fitur Unggulan

### Setup Mudah — 4 Langkah, 5 Menit

Tanpa SSH keys, tanpa port forwarding, tanpa firewall. Fork repo ini, salin perintah CRD dari halaman Google, tempel ke workflow GitHub Actions di fork Anda, dan konek dari browser. Seluruh stack — desktop environment, browser, code editor, dan remote access — terinstal otomatis.

### Pengalaman Remote yang Mulus

Sesi semua tiga desktop dikonfigurasi untuk operasi headless:

- **Direct exec** — session file melewati wrapper LightDM/Xsession yang menyebabkan crash "Oh no! Something has gone wrong"
- **Mesa software rendering** (`LIBGL_ALWAYS_SOFTWARE=1`) memastikan desktop render dengan benar di GitHub Actions runner tanpa GPU fisik
- **Screensaver dan lock dinonaktifkan** — sesi tetap hidup dan responsif, tidak pernah timeout atau mengunci Anda keluar
- **Resolusi otomatis 1600x1200** (semua tiga desktop) — xrandr auto-detect tampilan dan menerapkan resolusi optimal, plus fallback autostart

### Audio Streaming

Chrome Remote Desktop menyiarkan audio dari sesi remote ke browser secara otomatis. Tidak perlu konfigurasi PulseAudio atau PipeWire — ketiga desktop memakai audio stack Ubuntu default (XFCE memasang `pulseaudio` secara eksplisit), dan CRD menangani sisanya. Putar musik, tonton video, atau ikut video call — audio langsung jalan.

### Tema Catppuccin & Ikon Zafiro (Cinnamon & XFCE)

Workflow Cinnamon & XFCE hadir dengan tampilan premium langsung dari awal:

- **Catppuccin-B-LB-Dark** — tema GTK/Cinnamon gelap dengan elemen UI yang halus dan rounded
- **Zafiro-Nord-Black** — tema ikon flat minimalis berdasarkan palet warna Nord
- **Wallpaper Catppuccin Black Unicat** — sudah di-set sebagai background desktop
- Tema dan ikon diterapkan otomatis (Cinnamon via dconf, XFCE via xfconf), dengan autostart fallback agar persist lintas sesi

### Dev Tools Bawaan

| Tool | Kegunaan | Tersedia di |
|---|---|---|
| Google Chrome | Browser lengkap dengan ekstensi, profil, dan DevTools | Cinnamon, GNOME & XFCE |
| VS Code | Code editor dengan terminal, ekstensi, dan remote development | **GNOME saja**; untuk Cinnamon atau XFCE pasang via `sudo apt-get install code` |
| OpenCode CLI + Desktop | Asisten coding bertenaga AI | Cinnamon, GNOME & XFCE |
| Virtual Machine tools | QEMU/KVM, libvirt (`virsh`, `virt-install`), virt-manager, GNOME Boxes | Cinnamon, GNOME & XFCE |

GNOME menyediakan shortcut desktop (Antigravity, VS Code, OpenCode, Safe Upgrade). Cinnamon & XFCE menggunakan desktop bersih dengan tool di menu aplikasi.

### Virtualisasi KVM (Hardware-Accelerated VM)

Runner GitHub ini mengekspos `/dev/kvm` (Intel VT-x), jadi desktop bisa menjalankan **VM berakselerasi hardware** — bukan emulasi software yang lambat. Kedua workflow memasang stack QEMU/libvirt dan memberi akses langsung ke user `runner`:

- **QEMU/KVM** (`qemu-system-x86_64`, `/dev/kvm`) — virtualisasi CPU berakselerasi hardware
- **libvirt** (`libvirtd`, `virsh`, `virt-install`) — daemon manajemen VM, aktif saat build
- **Virtual Machine Manager** (`virt-manager`) — GUI lengkap untuk membuat/mengelola VM
- **GNOME Boxes** (`gnome-boxes`) — GUI sederhana untuk pemula

Kelebihan:

- Jalankan ISO apa pun (distro Linux lain, BSD, ISO Windows evaluasi) di dalam desktop remote dengan kecepatan CPU mendekati native
- Nested virtualization aktif — berguna untuk mengetes software yang butuh VT-x (VM di dalam VM bisa jalan)
- Tanpa setup — `runner` sudah masuk grup `kvm` + `libvirt`; tinggal buka **Virtual Machine Manager** atau **GNOME Boxes** → New VM → pilih ISO

Keterbatasan yang jujur:

- KVM **tidak** mempercepat rendering sesi CRD itu sendiri — desktop tetap memakai Mesa software rendering (tanpa GPU fisik). Jangan berharap UI desktop lebih cepat atau GPU acceleration dari fitur ini.
- Tidak ada GPU passthrough. VM sebaiknya memakai display software/virtio (mis. `virtio-gpu` / QXL); akselerasi 3D di dalam guest terbatas.
- Budget vCPU/RAM runner terbatas dan dipakai bersama sesi CRD yang sedang hidup — buat VM dengan ukuran wajar.
- `/dev/kvm` ada di runner tempat proyek ini dikembangkan, tetapi **tidak semua runner GitHub dijamin punya**. Kalau tidak ada, workflow hanya memberi peringatan (tidak gagal) dan VM akan jatuh ke emulasi QEMU TCG yang lambat.

### XFCE (Beta) — Desktop Paling Cepat

Untuk yang menginginkan responsivitas maksimal, coba workflow XFCE baru. Workflow ini memakai runner image **`ubuntu-26.04` public-preview** dan memasang XFCE + xfwm4 minimal (`xfce4`, `xfce4-session`, `xfwm4`, `xfce4-terminal`, `thunar`) — tanpa beban ekstra seperti obs-studio atau duplikat file manager. Sisanya sama dengan keluarga lainnya: sesi CRD direct-exec, auto-resolusi 1600x1200, safe-upgrade, tanpa snap, dan stack KVM (warn-only bila `/dev/kvm` tidak ada).

Batasan beta yang jujur:
- Image `ubuntu-26.04` adalah **public preview** GitHub (diluncurkan Juni 2026) — versi tool bisa beda dari 24.04, ada kemungkinan tidak stabil, plus potensi antrean.
- `/dev/kvm` **belum terverifikasi** di image 26.04; workflow hanya memberi peringatan jika tidak ada.
- Theming memakai `xfconf` (settings daemon XFCE), bukan dconf/gsettings.
- Nama perangkat CRD tampil sebagai **"xfce"** di halaman access.

### Upgrade Anti-Putus

Menjalankan `sudo apt upgrade` di dalam sesi CRD memutus koneksi (karena me-restart service CRD/GNOME/systemd). Helper [`safe-upgrade`](scripts/safe-upgrade.sh) menyelesaikan ini:

- Menahan paket kritis (CRD, desktop shell, systemd, kernel)
- Mengupgrade sisanya dengan aman
- MOTD warning di ketiga workflow (plus shortcut **Safe Upgrade** di GNOME) mencegah `apt upgrade` yang tidak sengaja

`safe-upgrade` juga dilengkapi fitur keamanan ekstra:

- **Version diff** — menampilkan setiap paket yang di-upgrade sebagai `nama: versi_lama → versi_baru`, plus paket baru dan yang dihapus
- **`--cleanup`** — menjalankan `apt-get autoremove` setelah upgrade untuk menghemat ruang disk
- **Rollback tracking** — snapshot semua versi paket sebelum & sesudah ke `/var/log/safe-upgrade-pre.log` dan `/var/log/safe-upgrade-post.log`
- **Tabel ringkasan** — ringkasan berwarna untuk paket yang di-upgrade / di-hold / dihapus dan durasi
- **Cek reboot kernel** — memperingatkan bila kernel baru terinstall tetapi belum aktif
- **Anti-interupsi** — trap `SIGINT`/`SIGTERM`/`EXIT` otomatis melepas hold paket bila upgrade dibatalkan di tengah jalan

---

## Mulai Cepat (5 menit)

Workflow memakai `workflow_dispatch`, jadi **harus dijalankan dari fork milik Anda** — GitHub hanya mengizinkan trigger Actions di repo yang Anda kontrol.

### 0. Fork repository ini

1. Buka <https://github.com/kiraadityaa/rich-linux-crd>.
2. Klik **Fork** (kanan atas) untuk membuat salinan di akun GitHub Anda.
3. Semua langkah berikut dilakukan di **fork Anda**.

### 1. Ambil perintah host CRD

1. Buka <https://remotedesktop.google.com/headless> di browser yang login akun Google.
2. Klik **Begin** → **Next** → **Authorize**.
3. Salin **perintah Debian Linux** yang muncul (diawali `DISPLAY= ... start-host ...`). Jangan dijalankan di lokal — cukup salin.

### 2. Jalankan workflow

1. Buka tab **Actions** di **fork Anda**.
2. Pilih workflow:
   - **RICH LINUX (Cinnamon + Chrome Remote Desktop)** → file `.github/workflows/cinnamon.yml`
   - **RICH LINUX (GNOME + Chrome Remote Desktop)** → file `.github/workflows/gnome.yml`
   - **RICH LINUX (XFCE Beta + Chrome Remote Desktop)** → file `.github/workflows/xfce.yml` (public-preview `ubuntu-26.04`, **beta**)
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
| Resolusi | Otomatis 1600x1200 via xrandr (retry + fallback autostart) | Otomatis 1600x1200 via xrandr (retry + fallback autostart) |
| Sesi CRD | `exec /usr/bin/cinnamon-session --session cinnamon` + `LIBGL_ALWAYS_SOFTWARE=1` | `exec /usr/bin/gnome-session --session=ubuntu` (auto-detect `ubuntu` > `gnome` > `gnome-xorg`) + `LIBGL_ALWAYS_SOFTWARE=1` |
| Display manager | Tidak dipakai (headless) | Tidak dipakai (headless) |
| Shortcut desktop | Tidak ada (desktop bersih) | Antigravity, VS Code, OpenCode, Safe Upgrade |
| Dev tools | Chrome + OpenCode CLI/Desktop | Chrome + VS Code + OpenCode CLI/Desktop |
| Virtualisasi | QEMU/KVM + libvirt + virt-manager + GNOME Boxes | QEMU/KVM + libvirt + virt-manager + GNOME Boxes |
| Screensaver, lock, suspend | Dinonaktifkan | Dinonaktifkan |
| Wallpaper | Catppuccin Black Unicat (via `org.cinnamon.desktop.background`) | Catppuccin Black Unicat (via `org.gnome.desktop.background`) |
| Upgrade | `safe-upgrade` di sesi (tanpa build-time full upgrade — bisa ditambah via kustomisasi) | Full upgrade di build-time + `safe-upgrade` di sesi |
| Cocok untuk | Tampilan ala Mint, ukuran lebih ringan, tema premium | Stabilitas maksimal |

> [!NOTE]
> **XFCE (Beta)** (`xfce.yml`) adalah pilihan desktop ketiga — paling cepat & responsif, memakai image public-preview `ubuntu-26.04`. Detail & batasan jujurnya ada di bagian fitur di atas.

---

## Troubleshooting: Error "Oh no! Something has gone wrong"

Gejala: PIN benar dan koneksi berhasil, tapi layar menampilkan wajah sedih dengan tombol **Log Out**.

Penyebab: session file lama memakai wrapper `lightdm-session` yang membutuhkan LightDM seat fisik — tidak ada di runner CRD yang headless.

Solusi sudah diterapkan di ketiga workflow (direct exec tanpa wrapper, plus paket Mesa/LLVMPipe untuk software rendering):

```bash
# Cinnamon
DESKTOP_SESSION=cinnamon
XDG_CURRENT_DESKTOP=X-Cinnamon
XDG_SESSION_TYPE=x11
XDG_RUNTIME_DIR=/run/user/$(id -u)
LIBGL_ALWAYS_SOFTWARE=1
exec /usr/bin/cinnamon-session --session cinnamon

# GNOME (auto-detect ubuntu > gnome > gnome-xorg)
DESKTOP_SESSION=ubuntu
XDG_CURRENT_DESKTOP=ubuntu:GNOME
XDG_SESSION_TYPE=x11
XDG_RUNTIME_DIR=/run/user/$(id -u)
LIBGL_ALWAYS_SOFTWARE=1
MUTTER_DEBUG_FORCE_SOFTWARE_RENDER=1
exec /usr/bin/gnome-session --session=ubuntu

# XFCE (Beta)
DESKTOP_SESSION=xfce
XDG_CURRENT_DESKTOP=XFCE
XDG_SESSION_TYPE=x11
XDG_RUNTIME_DIR=/run/user/$(id -u)
LIBGL_ALWAYS_SOFTWARE=1
exec /usr/bin/xfce4-session
```

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
| Upgrade + autoremove (hemat disk) | `safe-upgrade --cleanup` |
| Upgrade CRD/Chrome/desktop juga (SESI AKAN PUTUS) | `safe-upgrade --allow-crd-restart` / `safe-upgrade --include-desktop` |
| Dapat upgrade kritis tanpa putus | Re-run workflow Actions (workflow GNOME menjalankan full `upgrade` di build-time) |
| Lihat paket yang berubah | Baca version diff di output `safe-upgrade`, atau diff `/var/log/safe-upgrade-pre.log` vs `/var/log/safe-upgrade-post.log` |

Implementasi: [`scripts/safe-upgrade.sh`](scripts/safe-upgrade.sh). Dilengkapi **tabel ringkasan** berwarna, **version diff** (lama → baru), **rollback log** (`/var/log/safe-upgrade-pre.log` & `post.log`), **cek reboot kernel**, dan **trap anti-interupsi** yang otomatis melepas hold paket. Workflow GNOME juga memasang shortcut desktop **Safe Upgrade**; ketiga workflow memasang MOTD warning.

### virt-manager: "Failed to connect socket to '/var/run/libvirt/libvirt-sock': Permission denied"

Gejala: di dalam sesi CRD, `virt-manager` (atau `virsh`) tidak bisa connect ke `qemu:///system`, dan `test -r /dev/kvm` gagal.

Penyebab: ini **bukan** masalah polkit — melainkan keanggotaan grup. Daemon CRD me-spawn proses sesi dengan supplementary groups yang dimilikinya **saat daemon start**. Jika daemon sudah berjalan lebih dulu sebelum `usermod -aG kvm,libvirt runner` (mis. runner yang hidup terus lintas re-run workflow), proses turunannya tidak pernah menerima grup `kvm` / `libvirt`, sehingga tidak bisa membuka socket `srw-rw---- root:libvirt` maupun `/dev/kvm` (`crw-rw---- root kvm`).

Perbaikan (sudah diterapkan di ketiga workflow): step pemberi grup kini **me-restart daemon CRD** agar systemd meng-inisialisasi ulang supplementary groups dari `/etc/group`:

```bash
sudo usermod -aG kvm runner || true
sudo usermod -aG libvirt runner || true
sudo systemctl restart chrome-remote-desktop@runner || true   # opsional bila daemon belum jalan
```

Cek mandiri di dalam terminal CRD (`id -nG` harus memuat `kvm` dan `libvirt`):

```bash
id -nG
virsh -c qemu:///system list --all
```

> [!NOTE]
> Untuk sesi **live**, perintah yang sama berlaku juga — tetapi koneksi Anda putus sekali (konek ulang dengan PIN). Proses baru (terminal baru, aplikasi yang baru dibuka) mendapatkan grup setelah restart; terminal yang sudah terbuka sebelumnya tidak.

---

## Struktur repo

```
rich-linux-crd/
├── .github/workflows/       # cinnamon.yml, gnome.yml, xfce.yml (XFCE = beta)
├── assets/
│   ├── architecture.svg     # Diagram arsitektur di README
│   ├── cinnamon-theme.zip   # Tema Catppuccin + ikon Zafiro (otomatis diinstal oleh workflow Cinnamon & XFCE)
│   ├── rich-linux-crd-banner.svg
│   └── rich-linux-crd-logo.svg
├── opencode-setup/          # opencode-skills.md (panduan skill agent OpenCode + Context7)
├── scripts/                 # safe-upgrade.sh (version diff, --cleanup, rollback log, summary, reboot check)
├── README.md                # Dokumen utama (Inggris)
├── README.id.md             # File ini (Indonesia)
├── AGENTS.md                # Panduan melanjutkan proyek untuk agent/dev (Bahasa Indonesia)
├── LICENSE
└── .gitignore
```

---

## Kustomisasi

| Kebutuhan | Cara |
|---|---|
| Ganti PIN | Buat secret repo `CRD_PIN` (Settings → Secrets → Actions), minimal 6 digit |
| Ganti password user `runner` | Edit baris `echo "runner:...` di workflow. Default password "root" di ketiga workflow |
| Tambah aplikasi | Tambah step `apt-get install` baru sebelum step CRD, mis. `apt-get install -y code` untuk menambah VS Code di Cinnamon (needrestart sudah dinonaktifkan, jadi tetap senyap) |
| Ganti wallpaper | Edit URL download di step **Set Wallpaper** di workflow |
| Ganti resolusi tampilan | Edit config dummy Xorg dan perintah xrandr di step **Configure CRD Cinnamon Session** (STEP 08) di `cinnamon.yml` |
| Kelola virtual machine | Buka **Virtual Machine Manager** atau **GNOME Boxes** dari menu aplikasi → New VM → pilih ISO (`runner` sudah punya akses `/dev/kvm`) |
| Ganti tema | Ganti `cinnamon-theme.zip` di `assets/` dengan tema Anda sendiri (harus berisi direktori `themes/` dan `icons/`) |
| Perpanjang durasi | Edit `sleep 21600` di step **Keep Alive** (maks 6 jam karena limit Actions) |

---

## Catatan

- Workflow menggunakan `workflow_dispatch` — hanya berjalan saat Anda menjalankan secara manual.
- GitHub hanya mengizinkan Actions di repo yang Anda kontrol — **fork repository ini dulu**, lalu jalankan workflow dari fork Anda.
- Jangan commit perintah CRD ke repo (berisi kode auth sekali pakai). Cukup tempel ke input workflow.
- PIN default `123456` hanya untuk kemudahan. Untuk penggunaan serius, buat `CRD_PIN` custom.
- GitHub Actions free tier punya batas menit bulanan — pantau Settings → Billing.
- Workflow Cinnamon secara otomatis memasang tema Catppuccin dan ikon Zafiro dari `assets/cinnamon-theme.zip` — tidak perlu setup manual.
- Resolusi tampilan di-set ke 1600x1200 via xrandr auto-detection di session file (semua tiga desktop).
- KVM tersedia di runner GitHub ini (`/dev/kvm`, Intel VT-x, nested = aktif) — dipakai untuk **VM berakselerasi hardware** di dalam desktop. Fitur ini tidak mempercepat rendering CRD itu sendiri, dan ketersediaannya bisa berbeda antar fleet runner GitHub: kalau `/dev/kvm` tidak ada, workflow hanya memperingatkan (tidak gagal) dan VM akan jatuh ke QEMU TCG (lambat).
- Snap sengaja **dihapus permanen (purge + hold)** di ketiga workflow. Alasannya: `thunderbird` di Ubuntu 24.04 adalah *deb transisi* yang post-install-nya memaksa `snap install thunderbird` — di runner tanpa akses store yang baik, ini retry 30 menit dan menahan seluruh install desktop. `snapd`, `thunderbird` (snap-transitional), dan `firefox` di-purge setelah install dan di-hold agar tidak bisa ter-reinstall diam-diam. Tradeoff yang jujur: `snap install` tidak tersedia, Snap Store tidak muncul lagi di GNOME Software (source apt tetap ada), dan `firefox` dicopot — Google Chrome tetap sebagai browser. Kalau butuh browser lain, install Firefox ESR atau Chromium via apt.
- Workflow **XFCE Beta** (`xfce.yml`) memakai runner image `ubuntu-26.04` yang masih **public preview** (diumumkan Juni 2026). Belum seterbukti workflow 24.04; laporkan masalah ke issue tracker dengan nama workflow `xfce.yml`.
- `safe-upgrade` menyimpan snapshot versi paket sebelum/sesudah di `/var/log/safe-upgrade-pre.log` dan `/var/log/safe-upgrade-post.log` — diff keduanya untuk melihat perubahan persis.
- Proyek ini **hanya untuk penggunaan yang sah**. Lihat [Kebijakan Penggunaan & Disclaimer](#kebijakan-penggunaan--disclaimer).

---

## Kebijakan Penggunaan & Disclaimer

**Proyek ini ditujukan semata-mata untuk penggunaan yang sah dan wajar** — belajar, pengembangan, menguji sistem yang Anda miliki atau diberi izin, serta kerja remote desktop umum. Desktop yang dikirim adalah lingkungan tujuan umum yang netral (browser, terminal, editor, tool virtualisasi); dipakai untuk hal yang sah atau ilegal sepenuhnya adalah tanggung jawab orang yang menjalankannya.

### Tidak diperbolehkan (contoh konkret)

Menggunakan proyek ini untuk hal-hal berikut dilarang:

1. **Akses tanpa izin** — hacking, intrusion, cracking, pencurian kredensial/sesi terhadap sistem, akun, atau jaringan yang bukan milik Anda atau yang tidak berwenang Anda akses.
2. **Serangan siber** — meluncurkan serangan DDoS, menjalankan botnet, spam flooding, atau kampanye phishing.
3. **Malware** — membuat, menyebarkan, atau menghosting virus, ransomware, spyware, keylogger, atau perangkat lunak berbahaya lainnya.
4. **Pencurian data & penipuan** — mencuri, menjual, atau memperdagangkan data/akun curian; penipuan identitas atau pembayaran; pemerasan.
5. **Konten ilegal** — memiliki atau menyebarkan konten ilegal, termasuk materi pelecehan seksual anak (CSAM).
6. **Penyalahgunaan resource** — mining mata uang kripto pada resource yang bukan milik Anda atau tanpa izin (termasuk menit Actions runner yang menjalankan workflow ini).
7. **Pelanggaran terms of service** — apa pun yang melanggar GitHub Terms of Service, ketentuan Google Chrome Remote Desktop, lisensi Ubuntu/Microsoft, atau hukum lokal/nasional di wilayah hukum Anda.

### Konsekuensi

- **GitHub:** akun, repo, atau penggunaan Actions Anda bisa di-suspend/dihentikan karena pelanggaran ToS; menit bisa dicabut tanpa pengembalian.
- **Google:** akun Google dan akses Chrome Remote Desktop Anda bisa dinonaktifkan.
- **Hukum:** penyedia berhak melaporkan penyalahgunaan ke penegak hukum; Anda dapat menghadapi tuntutan pidana atau perdata sesuai hukum wilayah Anda — sepenuhnya menjadi tanggung jawab Anda.

### Model fork = tanggung jawab Anda

Saat Anda fork repo ini, workflow berjalan di bawah akun **Anda**, memakai menit Actions **Anda**, dan terdaftar ke akun Google **Anda**. Pengembang:

- **tidak memiliki kontrol, visibilitas, atau keterlibatan** apa pun atas fork atau sesi pengguna;
- tidak memantau, mencatat, atau mengakses sesi pengguna;
- tidak dapat membantu, mendukung, atau memverifikasi penggunaan instance seseorang.

Proyek ini disediakan **"AS-IS", tanpa jaminan apa pun**, di bawah Lisensi MIT. Pengembang **tidak bertanggung jawab** atas penyalahgunaan, kerugian, pelanggaran ToS, atau konsekuensi hukum apa pun yang timbul dari penggunaan atau fork proyek ini oleh siapa pun.

Gunakan dengan bijak: bangun, pelajari, dan uji — tetapi hanya pada sistem dan resource yang berhak Anda gunakan.

---

## Lisensi

MIT — lihat [LICENSE](LICENSE).
