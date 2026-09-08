#!/bin/bash
# safe-upgrade.sh — upgrade aman di dalam sesi Chrome Remote Desktop (GNOME/Cinnamon).
#
# Kenapa file ini ada:
#   `sudo apt upgrade -y` polos di dalam sesi CRD akan meng-upgrade
#   chrome-remote-desktop / gnome-shell / mutter / gdm3 / systemd / dbus,
#   lalu systemd me-restart service tersebut -> sesi X mati dan tidak bisa
#   konek ulang (harus re-run workflow GitHub Actions).
#
# Cara pakai (di terminal dalam sesi CRD sebagai user runner):
#   safe-upgrade                  # mode aman (default): hold paket kritis, upgrade sisanya
#   safe-upgrade --check          # dry-run saja, tidak mengubah apa pun
#   safe-upgrade --allow-crd-restart   # izinkan upgrade CRD/Chrome (SESI AKAN PUTUS!)
#   safe-upgrade --include-desktop     # izinkan upgrade GNOME/Cinnamon juga (SESI AKAN PUTUS!)
#   safe-upgrade --help
#
# Upgrade paket kritis yang benar: jangan dari dalam sesi,
# tapi re-run workflow Actions (build-time sudah melakukan full upgrade).

set -euo pipefail

CRITICAL_CRD=(
  chrome-remote-desktop
  google-chrome-stable
  google-chrome
)

CRITICAL_DESKTOP=(
  gnome-shell
  gnome-session
  gnome-session-bin
  mutter
  gdm3
  cinnamon
  cinnamon-session
  muffin
  nemo
)

CRITICAL_INIT=(
  systemd
  systemd-sysv
  libpam-systemd
  dbus
  dbus-x11
  dbus-user-session
  udev
)

CRITICAL_KERNEL=(
  linux-image-generic
  linux-headers-generic
  linux-generic
)

MODE="safe"
DRY_RUN=0
ALLOW_CRD=0
INCLUDE_DESKTOP=0

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \?//'
}

for arg in "$@"; do
  case "$arg" in
    --check) DRY_RUN=1 ;;
    --allow-crd-restart) ALLOW_CRD=1 ;;
    --include-desktop) INCLUDE_DESKTOP=1; ALLOW_CRD=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[FAIL] argumen tidak dikenal: $arg"; usage; exit 1 ;;
  esac
done

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
  if ! sudo -n true 2>/dev/null; then
    echo "[INFO] membutuhkan sudo, akan meminta password bila perlu."
  fi
fi

HOLD_LIST=()
if [ "$ALLOW_CRD" -eq 0 ]; then
  HOLD_LIST+=("${CRITICAL_CRD[@]}" "${CRITICAL_INIT[@]}" "${CRITICAL_KERNEL[@]}")
else
  # CRD diizinkan restart -> tetap tahan systemd/kernel agar VM tidak mati total.
  HOLD_LIST+=("${CRITICAL_INIT[@]}" "${CRITICAL_KERNEL[@]}")
fi
if [ "$INCLUDE_DESKTOP" -eq 0 ]; then
  HOLD_LIST+=("${CRITICAL_DESKTOP[@]}")
fi

# Hanya hold paket yang benar-benar terinstall (apt-mark hold paket-nonexistent = error).
INSTALLED_HOLD=()
for pkg in "${HOLD_LIST[@]}"; do
  if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
    INSTALLED_HOLD+=("$pkg")
  fi
done

echo "=============================================================="
echo "[safe-upgrade] mode: $MODE (dry-run=$DRY_RUN)"
echo "[safe-upgrade] paket kritis yang DITAHAN (${#INSTALLED_HOLD[@]}):"
printf '  - %s\n' "${INSTALLED_HOLD[@]}"
if [ "$ALLOW_CRD" -eq 1 ] || [ "$INCLUDE_DESKTOP" -eq 1 ]; then
  echo ""
  echo "!!! PERINGATAN: sesi CRD kemungkinan besar akan PUTUS. !!!"
  echo "!!! Siapkan re-run workflow bila perlu. Lanjut 5 detik... !!!"
  sleep 5
fi
echo "=============================================================="

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[CHECK] simulasi saja, tidak ada perubahan."
  $SUDO apt-get update
  if [ "${#INSTALLED_HOLD[@]}" -gt 0 ]; then
    $SUDO apt-mark hold "${INSTALLED_HOLD[@]}"
    $SUDO apt-get full-upgrade -s | head -n 60 || true
    # Kembalikan hold? hold memang diniatkan persisten selama sesi,
    # tapi untuk --check jangan ubah state: unhold kembali.
    $SUDO apt-mark unhold "${INSTALLED_HOLD[@]}" || true
  else
    $SUDO apt-get full-upgrade -s | head -n 60 || true
  fi
  echo "[CHECK] selesai. Jalankan tanpa --check untuk upgrade betulan."
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l

echo "[1/4] apt update..."
$SUDO apt-get update

echo "[2/4] hold paket kritis..."
if [ "${#INSTALLED_HOLD[@]}" -gt 0 ]; then
  $SUDO apt-mark hold "${INSTALLED_HOLD[@]}"
fi

echo "[3/4] upgrade paket aman (tanpa paket yang di-hold)..."
$SUDO apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo "[4/4] status akhir..."
echo "--- paket di-hold ---"
$SUDO apt-mark showhold || true
echo "--- service CRD ---"
systemctl is-active chrome-remote-desktop@"$(whoami)".service 2>/dev/null || systemctl is-active chrome-remote-desktop@runner.service 2>/dev/null || true
echo "--- versi desktop ---"
(command -v gnome-shell && gnome-shell --version) || (command -v cinnamon && cinnamon --version) || true

echo ""
echo "=============================================================="
echo "[OK] safe-upgrade selesai. Sesi CRD seharusnya tetap hidup."
echo "Sisa upgrade yang di-skip (CRD/GNOME/systemd/kernel):"
echo "jalankan ulang workflow Actions untuk mendapatkannya (build-time full upgrade)."
echo "Lihat daftar hold: sudo apt-mark showhold"
echo "Buka hold (JANGAN di dalam sesi kecuali siap putus): sudo apt-mark unhold <paket>"
echo "=============================================================="
