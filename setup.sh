#!/bin/bash
# Turns a fresh Debian 13 minimal install into the touch game console.
# Run once as root: sudo bash setup.sh
set -euo pipefail

PLAYER=player
REPO_URL="${REPO_URL:-https://github.com/t22admin/game-console.git}"
HOME_DIR=/home/$PLAYER
CONSOLE_DIR=$HOME_DIR/console

[ "$(id -u)" -eq 0 ] || { echo "Run with sudo"; exit 1; }
id "$PLAYER" >/dev/null 2>&1 || { echo "User '$PLAYER' not found"; exit 1; }

echo "==> Installing packages"
sed -i 's/^\(deb .* main\)$/\1 contrib non-free non-free-firmware/' /etc/apt/sources.list || true
apt-get update
apt-get install -y --no-install-recommends \
  cage chromium fonts-dejavu python3 git \
  plymouth plymouth-themes firmware-realtek \
  pipewire-audio wireplumber alsa-utils

echo "==> Wi-Fi fix for RTL8821CE (stop power-save dropouts)"
cat > /etc/modprobe.d/rtw88.conf <<'CONF'
options rtw88_core disable_lps_deep=y
options rtw88_pci disable_aspm=y
CONF

echo "==> Auto login on tty1"
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<CONF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $PLAYER --noclear %I \$TERM
CONF

echo "==> Kiosk session"
mkdir -p "$CONSOLE_DIR/launcher" "$CONSOLE_DIR/games"
cat > "$HOME_DIR/.bash_profile" <<'PROFILE'
# Only tty1 becomes the console. Other ttys (Ctrl+Alt+F2) and SSH get a normal shell.
if [ "$(tty)" = "/dev/tty1" ]; then
  [ -d ~/console/.git ] && timeout 20 git -C ~/console pull --ff-only -q 2>/dev/null
  python3 -m http.server 8080 --bind 127.0.0.1 -d ~/console >/dev/null 2>&1 &
  sleep 1
  exec cage -s -- chromium --kiosk --app=http://127.0.0.1:8080/launcher/ \
    --noerrdialogs --disable-infobars --disable-session-crashed-bubble \
    --disable-pinch --overscroll-history-navigation=0 \
    --autoplay-policy=no-user-gesture-required \
    --check-for-update-interval=31536000 --password-store=basic
fi
PROFILE

if [ -n "$REPO_URL" ]; then
  rm -rf "$CONSOLE_DIR" && git clone "$REPO_URL" "$CONSOLE_DIR"
elif [ ! -f "$CONSOLE_DIR/launcher/index.html" ]; then
  cat > "$CONSOLE_DIR/launcher/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8">
<style>html,body{margin:0;height:100%;background:#111;color:#fff;font:48px sans-serif;
display:flex;align-items:center;justify-content:center;user-select:none}</style></head>
<body>Console is ready. Games coming soon.</body></html>
HTML
fi
chown -R $PLAYER:$PLAYER "$HOME_DIR"

echo "==> Quiet boot with splash"
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
grep -q '^GRUB_TIMEOUT_STYLE' /etc/default/grub \
  && sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub \
  || echo 'GRUB_TIMEOUT_STYLE=hidden' >> /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 vt.global_cursor_default=0"/' /etc/default/grub
plymouth-set-default-theme -R spinner
update-grub

echo "==> Done. Rebooting into the console in 10 seconds (Ctrl+C to cancel)."
echo "    Admin escape: Ctrl+Alt+F2 for a login prompt, or SSH in over Wi-Fi."
sleep 10
reboot
