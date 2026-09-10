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
#   safe-upgrade --cleanup        # jalankan autoremove setelah upgrade (hemat disk)
#   safe-upgrade --allow-crd-restart   # izinkan upgrade CRD/Chrome (SESI AKAN PUTUS!)
#   safe-upgrade --include-desktop     # izinkan upgrade GNOME/Cinnamon juga (SESI AKAN PUTUS!)
#   safe-upgrade --help
#
# Upgrade paket kritis yang benar: jangan dari dalam sesi,
# tapi re-run workflow Actions (build-time sudah melakukan full upgrade).

set -euo pipefail

# ============================================================
# ANSI COLORS
# ============================================================
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_BOLD='\033[1m'
C_NC='\033[0m'

# ============================================================
# CRITICAL PACKAGES
# ============================================================
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

# ============================================================
# FLAGS
# ============================================================
DRY_RUN=0
ALLOW_CRD=0
INCLUDE_DESKTOP=0
CLEANUP=0

# ============================================================
# TRACKING (version diff + summary)
# ============================================================
PRE_SNAPSHOT_FILE=$(mktemp /tmp/safe-upgrade-pre-XXXXXX.txt)
POST_SNAPSHOT_FILE=$(mktemp /tmp/safe-upgrade-post-XXXXXX.txt)
UPGRADED_COUNT=0
REMOVED_COUNT=0
HELD_COUNT=0
START_TIME=$(date +%s)
HOLD_WAS_ACTIVE=0

# ============================================================
# TRAP: unhold paket saat interupsi (SIGINT/SIGTERM/EXIT)
# ============================================================
cleanup_on_exit() {
  local exit_code=$?
  if [ "$HOLD_WAS_ACTIVE" -eq 1 ] && [ "${#INSTALLED_HOLD[@]}" -gt 0 ]; then
    echo ""
    echo -e "${C_YELLOW}[CLEANUP] Melepas hold pada paket kritis...${C_NC}"
    $SUDO apt-mark unhold "${INSTALLED_HOLD[@]}" 2>/dev/null || true
    echo -e "${C_GREEN}[CLEANUP] Hold dilepas. Paket kritis kembali normal.${C_NC}"
  fi
  rm -f "$PRE_SNAPSHOT_FILE" "$POST_SNAPSHOT_FILE" 2>/dev/null || true
  exit "$exit_code"
}

trap cleanup_on_exit SIGINT SIGTERM EXIT

# ============================================================
# HELPERS
# ============================================================
usage() {
  sed -n '2,19p' "$0" | sed 's/^# \?//'
}

snapshot_versions() {
  # Simpan daftar "package version" ke file
  dpkg-query -W -f '${Package} ${Version}\n' 2>/dev/null | sort > "$1"
}

count_upgrades() {
  local count=0
  if [ -f "$PRE_SNAPSHOT_FILE" ] && [ -f "$POST_SNAPSHOT_FILE" ]; then
    count=$(comm -13 "$PRE_SNAPSHOT_FILE" "$POST_SNAPSHOT_FILE" | grep -vc "^$" || true)
  fi
  echo "$count"
}

show_version_diff() {
  # Tampilkan paket yang di-upgrade: name: old_ver -> new_ver
  if [ ! -f "$PRE_SNAPSHOT_FILE" ] || [ ! -f "$POST_SNAPSHOT_FILE" ]; then
    return
  fi

  echo ""
  echo -e "${C_CYAN}--- Version Diff ---${C_NC}"

  local has_diff=0
  while IFS=' ' read -r pkg post_ver; do
    local pre_ver
    pre_ver=$(grep "^${pkg} " "$PRE_SNAPSHOT_FILE" 2>/dev/null | awk '{print $2}')
    if [ -n "$pre_ver" ] && [ "$pre_ver" != "$post_ver" ]; then
      echo -e "  ${C_GREEN}+${C_NC} ${pkg}: ${C_YELLOW}${pre_ver}${C_NC} → ${C_GREEN}${post_ver}${C_NC}"
      has_diff=1
    elif [ -z "$pre_ver" ]; then
      echo -e "  ${C_GREEN}+${C_NC} ${pkg}: ${C_GREEN}(new) ${post_ver}${C_NC}"
      has_diff=1
    fi
  done < <(comm -13 "$PRE_SNAPSHOT_FILE" "$POST_SNAPSHOT_FILE")

  # Cek paket yang di-remove
  while IFS=' ' read -r pkg pre_ver; do
    if ! grep -q "^${pkg} " "$POST_SNAPSHOT_FILE" 2>/dev/null; then
      echo -e "  ${C_RED}-${C_NC} ${pkg}: ${C_RED}(removed) ${pre_ver}${C_NC}"
      REMOVED_COUNT=$((REMOVED_COUNT + 1))
      has_diff=1
    fi
  done < <(comm -23 "$PRE_SNAPSHOT_FILE" "$POST_SNAPSHOT_FILE")

  if [ "$has_diff" -eq 0 ]; then
    echo -e "  ${C_YELLOW}Tidak ada perubahan versi.${C_NC}"
  fi

  echo -e "${C_CYAN}--- End Version Diff ---${C_NC}"
}

print_summary() {
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - START_TIME))
  local mins=$((duration / 60))
  local secs=$((duration % 60))

  UPGRADED_COUNT=$(count_upgrades)
  HELD_COUNT=${#INSTALLED_HOLD[@]}

  echo ""
  echo -e "${C_CYAN}╔══════════════════════════════════════════╗${C_NC}"
  echo -e "${C_CYAN}║${C_NC}  ${C_BOLD}safe-upgrade summary${C_NC}                     ${C_CYAN}║${C_NC}"
  echo -e "${C_CYAN}╠══════════════════════════════════════════╣${C_NC}"
  printf "${C_CYAN}║${C_NC}  %-12s ${C_GREEN}%3d packages${C_NC}              ${C_CYAN}║${C_NC}\n" "Upgraded:" "$UPGRADED_COUNT"
  printf "${C_CYAN}║${C_NC}  %-12s ${C_YELLOW}%3d packages${C_NC}              ${C_CYAN}║${C_NC}\n" "Held:" "$HELD_COUNT"
  printf "${C_CYAN}║${C_NC}  %-12s ${C_RED}%3d packages${C_NC}              ${C_CYAN}║${C_NC}\n" "Removed:" "$REMOVED_COUNT"
  if [ "$CLEANUP" -eq 1 ]; then
    echo -e "${C_CYAN}║${C_NC}  Autoremove  : ${C_GREEN}yes${C_NC}                     ${C_CYAN}║${C_NC}"
  else
    echo -e "${C_CYAN}║${C_NC}  Autoremove  : no                        ${C_CYAN}║${C_NC}"
  fi
  printf "${C_CYAN}║${C_NC}  %-12s ${C_BOLD}%dm %ds${C_NC}                      ${C_CYAN}║${C_NC}\n" "Duration:" "$mins" "$secs"
  echo -e "${C_CYAN}╚══════════════════════════════════════════╝${C_NC}"
}

# ============================================================
# ARGUMENT PARSING
# ============================================================
for arg in "$@"; do
  case "$arg" in
    --check) DRY_RUN=1 ;;
    --cleanup) CLEANUP=1 ;;
    --allow-crd-restart) ALLOW_CRD=1 ;;
    --include-desktop) INCLUDE_DESKTOP=1; ALLOW_CRD=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo -e "${C_RED}[FAIL] argumen tidak dikenal: $arg${C_NC}"; usage; exit 1 ;;
  esac
done

# ============================================================
# SUDO DETECTION
# ============================================================
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
  if ! sudo -n true 2>/dev/null; then
    echo -e "${C_YELLOW}[INFO] membutuhkan sudo, akan meminta password bila perlu.${C_NC}"
  fi
fi

# ============================================================
# BUILD HOLD LIST
# ============================================================
INSTALLED_HOLD=()
HOLD_LIST=()
if [ "$ALLOW_CRD" -eq 0 ]; then
  HOLD_LIST+=("${CRITICAL_CRD[@]}" "${CRITICAL_INIT[@]}" "${CRITICAL_KERNEL[@]}")
else
  HOLD_LIST+=("${CRITICAL_INIT[@]}" "${CRITICAL_KERNEL[@]}")
fi
if [ "$INCLUDE_DESKTOP" -eq 0 ]; then
  HOLD_LIST+=("${CRITICAL_DESKTOP[@]}")
fi

for pkg in "${HOLD_LIST[@]}"; do
  if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
    INSTALLED_HOLD+=("$pkg")
  fi
done

# ============================================================
# BANNER
# ============================================================
echo ""
echo -e "${C_CYAN}==============================================================${C_NC}"
echo -e "${C_BOLD}[safe-upgrade]${C_NC} mode: $([ "$DRY_RUN" -eq 1 ] && echo "dry-run" || echo "live")"
echo -e "${C_CYAN}==============================================================${C_NC}"
echo -e "  paket kritis yang DITAHAN (${#INSTALLED_HOLD[@]}):"
for pkg in "${INSTALLED_HOLD[@]}"; do
  echo -e "    ${C_YELLOW}-${C_NC} $pkg"
done
if [ "$ALLOW_CRD" -eq 1 ] || [ "$INCLUDE_DESKTOP" -eq 1 ]; then
  echo ""
  echo -e "  ${C_RED}!!! PERINGATAN: sesi CRD kemungkinan besar akan PUTUS. !!!${C_NC}"
  echo -e "  ${C_RED}!!! Siapkan re-run workflow bila perlu. Lanjut 5 detik... !!!${C_NC}"
  sleep 5
fi
echo -e "${C_CYAN}==============================================================${C_NC}"
echo ""

# ============================================================
# DRY-RUN MODE
# ============================================================
if [ "$DRY_RUN" -eq 1 ]; then
  echo -e "${C_CYAN}[CHECK] simulasi saja, tidak ada perubahan.${C_NC}"
  $SUDO apt-get update
  if [ "${#INSTALLED_HOLD[@]}" -gt 0 ]; then
    $SUDO apt-mark hold "${INSTALLED_HOLD[@]}"
    $SUDO apt-get full-upgrade -s | head -n 60 || true
    $SUDO apt-mark unhold "${INSTALLED_HOLD[@]}" || true
  else
    $SUDO apt-get full-upgrade -s | head -n 60 || true
  fi
  echo ""
  echo -e "${C_GREEN}[CHECK] selesai. Jalankan tanpa --check untuk upgrade betulan.${C_NC}"
  exit 0
fi

# ============================================================
# PRE-UPGRADE: snapshot versi + rollback log
# ============================================================
echo -e "${C_CYAN}[1/5] Pre-upgrade snapshot...${C_NC}"
snapshot_versions "$PRE_SNAPSHOT_FILE"
$SUDO cp "$PRE_SNAPSHOT_FILE" /var/log/safe-upgrade-pre.log 2>/dev/null || true
echo -e "  snapshot: $(wc -l < "$PRE_SNAPSHOT_FILE") paket tercatat"

# ============================================================
# STEP 1: APT UPDATE
# ============================================================
echo -e "${C_CYAN}[2/5] apt update...${C_NC}"
$SUDO apt-get update

# ============================================================
# STEP 2: HOLD PAKET KRITIS
# ============================================================
echo -e "${C_CYAN}[3/5] Hold paket kritis...${C_NC}"
if [ "${#INSTALLED_HOLD[@]}" -gt 0 ]; then
  HOLD_WAS_ACTIVE=1
  $SUDO apt-mark hold "${INSTALLED_HOLD[@]}"
  echo -e "  ${C_GREEN}${#INSTALLED_HOLD[@]} paket di-hold.${C_NC}"
fi

# ============================================================
# STEP 3: UPGRADE
# ============================================================
echo -e "${C_CYAN}[4/5] Upgrade paket aman...${C_NC}"
$SUDO apt-get upgrade -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"

# ============================================================
# STEP 4 (optional): AUTOREMOVE
# ============================================================
if [ "$CLEANUP" -eq 1 ]; then
  echo -e "${C_CYAN}[4b/5] Cleanup (autoremove)...${C_NC}"
  REMOVED_BEFORE=$($SUDO dpkg -l | grep -c "^rc" || true)
  $SUDO apt-get autoremove -y || true
  REMOVED_AFTER=$($SUDO dpkg -l | grep -c "^rc" || true)
  REMOVED_COUNT=$((REMOVED_BEFORE - REMOVED_AFTER))
  echo -e "  ${C_GREEN}${REMOVED_COUNT} paket di-remove.${C_NC}"
fi

# ============================================================
# POST-UPGRADE: snapshot versi + rollback log
# ============================================================
echo -e "${C_CYAN}[5/5] Post-upgrade snapshot & status...${C_NC}"
snapshot_versions "$POST_SNAPSHOT_FILE"
$SUDO cp "$POST_SNAPSHOT_FILE" /var/log/safe-upgrade-post.log 2>/dev/null || true
echo -e "  snapshot: $(wc -l < "$POST_SNAPSHOT_FILE") paket tercatat"

echo ""
echo -e "--- paket di-hold ---"
$SUDO apt-mark showhold || true

echo ""
echo -e "--- service CRD ---"
if systemctl is-active chrome-remote-desktop@"$(whoami)".service 2>/dev/null; then
  echo -e "  ${C_GREEN}active${C_NC}"
elif systemctl is-active chrome-remote-desktop@runner.service 2>/dev/null; then
  echo -e "  ${C_GREEN}active${C_NC}"
else
  echo -e "  ${C_RED}inactive atau tidak ditemukan${C_NC}"
fi

echo ""
echo -e "--- versi desktop ---"
(command -v gnome-shell && gnome-shell --version) || (command -v cinnamon && cinnamon --version) || true

echo ""
echo -e "--- kernel reboot check ---"
RUNNING_KERNEL=$(uname -r)
INSTALLED_KERNEL=$(dpkg-query -W -f '${Version}\n' linux-image-generic 2>/dev/null || echo "unknown")
if [[ "$RUNNING_KERNEL" != *"$INSTALLED_KERNEL"* ]] && [ "$INSTALLED_KERNEL" != "unknown" ]; then
  echo -e "  ${C_YELLOW}WARNING: kernel baru terinstall (${INSTALLED_KERNEL}), running: ${RUNNING_KERNEL}${C_NC}"
  echo -e "  ${C_YELLOW}Pertimbangkan reboot setelah sesi CRD selesai.${C_NC}"
else
  echo -e "  ${C_GREEN}Kernel up-to-date.${C_NC}"
fi

# ============================================================
# VERSION DIFF
# ============================================================
show_version_diff

# ============================================================
# UNHOLD (normal exit — cleanup_on_exit juga handle interupsi)
# ============================================================
if [ "$HOLD_WAS_ACTIVE" -eq 1 ] && [ "${#INSTALLED_HOLD[@]}" -gt 0 ]; then
  echo ""
  echo -e "${C_CYAN}[CLEANUP] Melepas hold pada paket kritis...${C_NC}"
  $SUDO apt-mark unhold "${INSTALLED_HOLD[@]}"
  HOLD_WAS_ACTIVE=0
  echo -e "${C_GREEN}[CLEANUP] Hold dilepas. Paket kritis kembali normal.${C_NC}"
fi

# ============================================================
# SUMMARY TABLE
# ============================================================
print_summary

echo ""
echo -e "${C_GREEN}==============================================================${C_NC}"
echo -e "${C_GREEN}[OK] safe-upgrade selesai. Sesi CRD seharusnya tetap hidup.${C_NC}"
echo -e "  Log upgrade:"
echo -e "    pre  : ${C_CYAN}/var/log/safe-upgrade-pre.log${C_NC}"
echo -e "    post : ${C_CYAN}/var/log/safe-upgrade-post.log${C_NC}"
echo -e "  Sisa upgrade yang di-skip (CRD/GNOME/systemd/kernel):"
echo -e "    jalankan ulang workflow Actions untuk mendapatkannya."
echo -e "  Lihat daftar hold: ${C_CYAN}sudo apt-mark showhold${C_NC}"
echo -e "  Buka hold (JANGAN di dalam sesi kecuali siap putus):"
echo -e "    ${C_CYAN}sudo apt-mark unhold <paket>${C_NC}"
echo -e "${C_GREEN}==============================================================${C_NC}"
