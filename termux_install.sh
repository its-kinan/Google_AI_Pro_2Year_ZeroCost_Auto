#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Google AI Pro — Termux/Android installer
#  Runs INSIDE Termux (not inside proot-distro)
#
#  What this does:
#    1. Updates Termux packages
#    2. Installs proot-distro (Ubuntu 22.04 container, no root)
#    3. Inside proot Ubuntu: installs Python 3, Chromium, Playwright
#    4. Copies the app files into the proot home directory
#    5. Writes the config template
#
#  Usage (from Termux):
#    chmod +x termux_install.sh && bash termux_install.sh
# ============================================================
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DISTRO="ubuntu"
PROOT_HOME="/root"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Google AI Pro 2Year ZeroCost — Termux Installer     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── 1. Termux base packages ──────────────────────────────────
echo "[1/5] Updating Termux packages..."
pkg update -y -o Dpkg::Options::="--force-confold" 2>/dev/null || pkg update -y
pkg install -y proot-distro iproute2 procps 2>/dev/null || true

# ── 2. Install Ubuntu proot-distro ──────────────────────────
echo "[2/5] Installing proot-distro Ubuntu (first run only, ~300 MB)..."
proot-distro install "$DISTRO" 2>/dev/null || echo "  (already installed, skipping)"

# ── 3. Inside proot: system packages ────────────────────────
echo "[3/5] Installing system packages inside proot-distro Ubuntu..."
proot-distro login "$DISTRO" -- bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq \
        python3 python3-pip python3-venv \
        chromium-browser \
        libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
        libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 \
        libxrandr2 libgbm1 libasound2 libpango-1.0-0 libcairo2 \
        fonts-liberation fonts-noto-cjk \
        2>/dev/null
    echo '  system packages OK'
"

# ── 4. Inside proot: Python packages ────────────────────────
echo "[4/5] Installing Python packages inside proot-distro Ubuntu..."
proot-distro login "$DISTRO" -- bash -c "
    set -e
    pip3 install --quiet --upgrade pip
    pip3 install --quiet fastapi uvicorn playwright pydantic

    # Install Playwright Chromium (ARM64 binary, ~200 MB)
    # Only if system chromium is not found or we want Playwright's own binary
    if ! command -v chromium-browser &>/dev/null; then
        echo '  Installing Playwright Chromium (ARM64)...'
        playwright install chromium
        playwright install-deps chromium 2>/dev/null || true
    else
        echo '  Using system chromium-browser, skipping Playwright chromium download'
        # Still install dependencies
        playwright install-deps chromium 2>/dev/null || true
    fi
    echo '  Python packages OK'
"

# ── 5. Copy app files into proot home ───────────────────────
echo "[5/5] Copying app files into proot-distro home..."
APP_DST="$HOME/.proot-distro/$DISTRO/root/google-ai-pro"
proot-distro login "$DISTRO" -- bash -c "mkdir -p /root/google-ai-pro/templates /root/google-ai-pro/profiles /root/google-ai-pro/screenshots"

# Copy files using proot-distro's filesystem path
PROOT_FS="$HOME/.proot-distro/$DISTRO"
# Try the standard proot-distro rootfs path
for TRY_PATH in \
    "$HOME/.proot-distro/$DISTRO/root" \
    "$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO/root" \
    ""; do
    if [ -n "$TRY_PATH" ] && [ -d "$TRY_PATH" ]; then
        PROOT_ROOT="$TRY_PATH"
        break
    fi
done

if [ -n "$PROOT_ROOT" ]; then
    mkdir -p "$PROOT_ROOT/google-ai-pro/templates" \
              "$PROOT_ROOT/google-ai-pro/profiles" \
              "$PROOT_ROOT/google-ai-pro/screenshots"
    cp "$REPO_DIR/automation_engine.py" "$PROOT_ROOT/google-ai-pro/"
    cp "$REPO_DIR/app.py"               "$PROOT_ROOT/google-ai-pro/"
    cp "$REPO_DIR/templates/index.html" "$PROOT_ROOT/google-ai-pro/templates/"
    if [ -f "$REPO_DIR/config.json" ]; then
        cp "$REPO_DIR/config.json" "$PROOT_ROOT/google-ai-pro/"
    fi
    echo "  Files copied to $PROOT_ROOT/google-ai-pro/"
else
    echo "  WARNING: Could not locate proot-distro rootfs automatically."
    echo "  Please copy the app files manually:"
    echo "    proot-distro login ubuntu"
    echo "    mkdir -p /root/google-ai-pro/templates"
    echo "    # then copy automation_engine.py, app.py, templates/index.html"
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Installation complete!                              ║"
echo "║                                                      ║"
echo "║  To run:                                             ║"
echo "║    bash termux_start.sh                              ║"
echo "║                                                      ║"
echo "║  Then open in your phone browser:                   ║"
echo "║    http://127.0.0.1:8765                             ║"
echo "╚══════════════════════════════════════════════════════╝"
