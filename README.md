# RICH Linux CRD

**English** | [Bahasa Indonesia](README.id.md)

> Ubuntu 24.04 on GitHub Actions + Chrome Remote Desktop. Pick your desktop — lightweight **Cinnamon** or stable **GNOME** — and connect from anywhere with a PIN.

<p align="center">
  <img src="assets/rich-linux-crd-banner.svg" alt="RICH Linux CRD banner" width="820" />
</p>

<p align="center">
  <a href="https://github.com/kiraadityaa/rich-linux-crd/actions/workflows/cinnamon.yml"><img src="https://github.com/kiraadityaa/rich-linux-crd/actions/workflows/cinnamon.yml/badge.svg" alt="Cinnamon workflow status" /></a>
  <a href="https://github.com/kiraadityaa/rich-linux-crd/actions/workflows/gnome.yml"><img src="https://github.com/kiraadityaa/rich-linux-crd/actions/workflows/gnome.yml/badge.svg" alt="GNOME workflow status" /></a>
  <img src="https://img.shields.io/badge/Ubuntu-24.04-E95420?style=flat-square&logo=ubuntu&logoColor=white" alt="Ubuntu 24.04" />
  <img src="https://img.shields.io/badge/Cinnamon-Full-success?style=flat-square" alt="Cinnamon" />
  <img src="https://img.shields.io/badge/GNOME-Stable-blue?style=flat-square&logo=gnome&logoColor=white" alt="GNOME" />
  <img src="https://img.shields.io/badge/Chrome_Remote_Desktop-ready-4285F4?style=flat-square&logo=googlechrome&logoColor=white" alt="Chrome Remote Desktop" />
  <img src="https://img.shields.io/badge/VS_Code-included-007ACC?style=flat-square&logo=visualstudiocode&logoColor=white" alt="VS Code" />
  <img src="https://img.shields.io/badge/OpenCode-included-000000?style=flat-square" alt="OpenCode" />
  <img src="https://img.shields.io/badge/Theme-Catppuccin-green?style=flat-square" alt="Catppuccin Theme" />
  <img src="https://img.shields.io/badge/Resolution-1600x1200-blue?style=flat-square" alt="1600x1200" />
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="MIT License" />
</p>

![Architecture: user input flows through GitHub Actions install and CRD registration to browser connect](assets/architecture.svg)

Image sources: workflow status badges from GitHub Actions, technology badges from Shields.io, banner from [`assets/rich-linux-crd-banner.svg`](assets/rich-linux-crd-banner.svg) and architecture diagram from [`assets/architecture.svg`](assets/architecture.svg) in this repository. No external stock photography.

---

## Overview

| Feature | Detail |
|---|---|
| Two desktops | Cinnamon Full (approx. 1 GB) or GNOME Ubuntu Desktop (approx. 2 GB) |
| Instant remote access | Chrome Remote Desktop, default PIN `123456` (customizable via secret) |
| Dev tools included | Google Chrome, VS Code, OpenCode CLI + OpenCode Desktop |
| Session length | Automatic keep-alive per workflow run (up to 6 hours) |
| Crash-resistant session | Direct `exec` without `Xsession`/`lightdm` wrappers + Mesa software rendering (fixes the "Oh no! Something has gone wrong" screen) |
| Disconnect-safe upgrades | Full `upgrade` at build time + [`safe-upgrade`](scripts/safe-upgrade.sh) helper inside the session (holds CRD/desktop/systemd packages) |
| Quiet installs | Needrestart apt hook disabled (`/etc/apt/apt.conf.d/20needrestart` removed) → no "Scanning processes..." output and no auto service restarts during any install/upgrade |
| Catppuccin theme + Zafiro icons | Cinnamon workflow auto-extracts `cinnamon-theme.zip` → Catppuccin-B-LB-Dark theme + Zafiro-Nord-Black icon theme, applied via dconf |
| Auto resolution 1600x1200 | Dual-layer: Xorg dummy config + xrandr auto-detect loop in session file |
| Audio streaming | Chrome Remote Desktop natively streams audio from the remote session — no extra PulseAudio/PipeWire config needed |
| Smooth remote experience | Mesa software rendering, direct exec session, disabled screensaver/lock → responsive desktop without crashes |
| Zero-config setup | 3-step Quick Start: copy CRD command → run workflow → connect with PIN. No SSH, no port forwarding, no firewall config |
| Wallpaper included | Catppuccin **Black Unicat** preinstalled for the `runner` user on both desktops |
| Desktop layout | Cinnamon: clean desktop (no shortcuts) — tools in the app menu; GNOME: shortcuts (Antigravity, VS Code, OpenCode, Safe Upgrade) |

---

## Features at a glance

### Easy Setup — 3 Steps, 5 Minutes

No SSH keys, no port forwarding, no firewall rules. Just copy a CRD command from Google's page, paste it into a GitHub Actions workflow, and connect from your browser. The entire stack — desktop environment, browser, code editor, and remote access — installs automatically.

### Smooth Remote Experience

Both Cinnamon and GNOME sessions are configured for headless operation:

- **Direct exec** session files bypass LightDM/Xsession wrappers that cause the "Oh no! Something has gone wrong" crash
- **Mesa software rendering** (`LIBGL_ALWAYS_SOFTWARE=1`) ensures the desktop renders correctly on GitHub Actions runners without a physical GPU
- **Screensaver and lock disabled** — the session stays alive and responsive, never timing out or locking you out
- **Auto resolution 1600x1200** (Cinnamon) — xrandr auto-detects the display and applies the optimal resolution

### Audio Streaming

Chrome Remote Desktop streams audio from the remote session to your browser automatically. No PulseAudio or PipeWire configuration is needed — Cinnamon and GNOME both use the default Ubuntu audio stack, and CRD handles the rest. Play music, watch videos, or join video calls — audio works out of the box.

### Catppuccin Theme & Zafiro Icons (Cinnamon)

The Cinnamon workflow ships with a premium look out of the box:

- **Catppuccin-B-LB-Dark** — a dark GTK/Cinnamon theme with smooth, rounded UI elements
- **Zafiro-Nord-Black** — a flat, minimal icon theme based on the Nord color palette
- **Catppuccin Black Unicat** wallpaper — pre-set as the desktop background
- Theme and icons are applied automatically via dconf, with an autostart fallback to persist across sessions

### Built-in Dev Tools

| Tool | Purpose |
|---|---|
| Google Chrome | Full browser with extensions, profiles, and DevTools |
| VS Code | Code editor with terminal, extensions, and remote development |
| OpenCode CLI + Desktop | AI-powered coding assistant |

All tools are pre-installed and available from the application menu (Cinnamon) or desktop shortcuts (GNOME).

### Disconnect-Safe Upgrades

Running `sudo apt upgrade` inside a CRD session drops the connection (it restarts CRD/GNOME/systemd services). The [`safe-upgrade`](scripts/safe-upgrade.sh) helper solves this:

- Holds critical packages (CRD, desktop shell, systemd, kernel)
- Upgrades everything else safely
- A MOTD warning in both workflows (plus a **Safe Upgrade** shortcut on GNOME) prevents accidental `apt upgrade`

---

## How it works

```mermaid
flowchart LR
    A["You: run workflow + paste CRD command"] --> B["GitHub Actions ubuntu-24.04"]
    B --> C["Install: Cinnamon/GNOME, Chrome, VS Code, OpenCode, CRD"]
    C --> D["Register host, PIN 123456"]
    D --> E["X11 session without LightDM"]
    E --> F["You connect via remotedesktop.google.com/access"]
```

---

## Quick Start (5 minutes)

### 1. Get the CRD host command

1. Open <https://remotedesktop.google.com/headless> in a browser logged in to your Google account.
2. Click **Begin** → **Next** → **Authorize**.
3. Copy the **Debian Linux** command shown (starts with `DISPLAY= ... start-host ...`). Do not run it locally — just copy.

### 2. Run the workflow

1. Open the **Actions** tab in this repository.
2. Select a workflow:
   - **RICH LINUX (Cinnamon + Chrome Remote Desktop)** → file `.github/workflows/cinnamon.yml`
   - **RICH LINUX (GNOME + Chrome Remote Desktop)** → file `.github/workflows/gnome.yml`
3. Click **Run workflow**, paste the CRD command into the `crd_host_command` field, click **Run**.
4. Wait approx. 5–10 minutes until the log shows `CHROME REMOTE DESKTOP READY`.

### 3. Connect

1. Open <https://remotedesktop.google.com/access>.
2. Click your device → enter the PIN:
   - Default: `123456`
   - Custom: create a repository secret named `CRD_PIN` (minimum 6 digits) before running the workflow.
3. You are in the desktop.

---

## Cinnamon vs GNOME

|  | Cinnamon (`cinnamon.yml`) | GNOME (`gnome.yml`) |
|---|---|---|
| Look and feel | Classic, Linux Mint style | Modern Ubuntu style |
| Install size | Approx. 1 GB | Approx. 2 GB |
| Theme | Catppuccin-B-LB-Dark + Zafiro-Nord-Black icons (auto-installed) | Default Adwaita |
| Resolution | Auto 1600x1200 via xrandr | CRD default |
| CRD session | `exec /usr/bin/cinnamon-session --session cinnamon` + `LIBGL_ALWAYS_SOFTWARE=1` | `exec /usr/bin/gnome-session --session=ubuntu` + `LIBGL_ALWAYS_SOFTWARE=1` |
| Display manager | Not used (headless) | Not used (headless) |
| Desktop shortcuts | None (clean desktop) | Antigravity, VS Code, OpenCode, Safe Upgrade |
| Screensaver, lock, suspend | Disabled (autostart + dconf no-lock, packages kept installed) | Disabled (dconf + gsettings no-lock, suspend set to `nothing`) |
| Wallpaper | Catppuccin Black Unicat (via `org.cinnamon.desktop.background`) | Catppuccin Black Unicat (via `org.gnome.desktop.background`) |
| Upgrades | Build-time full upgrade + `safe-upgrade` in session | Build-time full upgrade + `safe-upgrade` in session |
| Best for | Mint-style look, lighter footprint, premium theme | Maximum stability |

---

## Troubleshooting

### Error: "Oh no! Something has gone wrong"

Symptom: the PIN is correct and the connection succeeds, but the screen shows a sad face with a **Log Out** button.

Cause: the session file used a `lightdm-session` wrapper that requires a physical LightDM seat — which does not exist on the headless CRD runner.

Fix already applied in both workflows:

```bash
# Cinnamon
DESKTOP_SESSION=cinnamon
XDG_CURRENT_DESKTOP=X-Cinnamon
XDG_SESSION_TYPE=x11
XDG_RUNTIME_DIR=/run/user/$(id -u)
LIBGL_ALWAYS_SOFTWARE=1
exec /usr/bin/cinnamon-session --session cinnamon

# GNOME (auto-detects ubuntu > gnome > gnome-xorg)
DESKTOP_SESSION=ubuntu
XDG_CURRENT_DESKTOP=ubuntu:GNOME
XDG_SESSION_TYPE=x11
XDG_RUNTIME_DIR=/run/user/$(id -u)
LIBGL_ALWAYS_SOFTWARE=1
MUTTER_DEBUG_FORCE_SOFTWARE_RENDER=1
exec /usr/bin/gnome-session --session=ubuntu
```

Plus Mesa/LLVMPipe packages for software rendering, with no conflicting LightDM installation.

### Session drops after `apt upgrade` and cannot reconnect

Symptom: after `sudo apt update && sudo apt upgrade -y`, the session drops suddenly and reconnecting fails. The log shows systemd restarting something.

Cause: the upgrade also raises `chrome-remote-desktop` / `gnome-shell` / `mutter` / `gdm3` / `systemd` / `dbus`, then restarts their services — killing the running X session mid-upgrade.

> [!WARNING]
> Never run plain `sudo apt upgrade -y` inside the CRD session. It restarts the display stack and drops the connection (recovery requires re-running the workflow).

| Need | Command |
|---|---|
| Safe daily upgrade (in the CRD terminal) | `safe-upgrade` (automatically holds critical packages, upgrades the rest) |
| Preview without changing anything | `safe-upgrade --check` |
| Upgrade CRD/Chrome/desktop too (WILL DISCONNECT) | `safe-upgrade --allow-crd-restart` / `safe-upgrade --include-desktop` |
| Get critical upgrades without disconnecting | Re-run the Actions workflow (it already runs a full `upgrade` at build time, before CRD starts) |

> [!TIP]
> Implementation: [`scripts/safe-upgrade.sh`](scripts/safe-upgrade.sh). The GNOME workflow also installs a **Safe Upgrade** desktop shortcut; both workflows set a MOTD warning.

---

## Repository structure

```
rich-linux-crd/
├── .github/
│   └── workflows/
│       ├── cinnamon.yml   # RICH LINUX (Cinnamon + CRD)
│       └── gnome.yml      # RICH LINUX (GNOME + CRD)
├── assets/
│   ├── architecture.svg        # Architecture diagram used in this README
│   ├── cinnamon-theme.zip      # Catppuccin theme + Zafiro icons (auto-installed by Cinnamon workflow)
│   └── rich-linux-crd-banner.svg
├── scripts/
│   └── safe-upgrade.sh  # Safe in-session upgrade (replacement for apt upgrade)
├── README.md            # This file (English)
├── README.id.md         # Indonesian summary
├── LICENSE
└── .gitignore
```

---

## Customization

| Need | How |
|---|---|
| Change PIN | Create a `CRD_PIN` repository secret (Settings → Secrets → Actions), 6+ digits |
| Change the `runner` user password | Edit the `echo "runner:...` line in the workflow |
| Add applications | Add a new `apt-get install` step before the CRD step (needrestart is already disabled, so it stays quiet) |
| Change the wallpaper | Edit the download URL in the **Set Wallpaper** step of the workflow |
| Change the display resolution | Edit the Xorg dummy config and xrandr commands in the **Configure CRD Cinnamon Session** step (STEP 09) of `cinnamon.yml` |
| Change the theme | Replace `cinnamon-theme.zip` in `assets/` with your own theme archive (must contain `themes/` and `icons/` directories) |
| Extend duration | Edit `sleep 21600` in the **Keep Alive** step (max 6 hours due to the Actions limit) |

---

## Notes

- Workflows use `workflow_dispatch` — they only run when you trigger them manually.
- Never commit your CRD command to the repository (it contains a one-time auth code). Paste it only into the workflow input.
- The default PIN `123456` is for convenience only. For serious use, set a custom `CRD_PIN`.
- The GitHub Actions free tier has monthly minute limits — monitor Settings → Billing.
- The Cinnamon workflow automatically installs the Catppuccin theme and Zafiro icons from `assets/cinnamon-theme.zip` — no manual setup required.
- Display resolution is set to 1600x1200 via xrandr auto-detection in the Cinnamon session file.

---

## Contributing

Pull requests and issues are welcome. If you find a new session error, please include:

1. Workflow name (Cinnamon / GNOME),
2. The **Verify Installation** step log excerpt,
3. The runner's `~/.chrome-remote-desktop-*.log` contents.

---

## License

MIT — see [LICENSE](LICENSE).
