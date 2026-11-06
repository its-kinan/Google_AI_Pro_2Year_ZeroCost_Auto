#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Google AI Pro — Termux/Android installer
#  Runs INSIDE Termux (not inside proot-distro)
#
#  Usage:
#    chmod +x termux_install.sh && bash termux_install.sh
# ============================================================
set -e

DISTRO="ubuntu"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Google AI Pro 2Year ZeroCost — Termux Installer     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── 1. Termux base packages ──────────────────────────────────
echo "[1/4] Updating Termux packages..."
pkg update -y -o Dpkg::Options::="--force-confold" 2>/dev/null || pkg update -y
pkg install -y proot-distro iproute2 procps 2>/dev/null || true

# ── 2. Install Ubuntu proot-distro ──────────────────────────
echo "[2/4] Installing proot-distro Ubuntu (first run only, ~300 MB)..."
proot-distro install "$DISTRO" 2>/dev/null || echo "  (already installed, skipping)"

# ── 3. Inside proot: system packages ────────────────────────
echo "[3/4] Installing system packages inside proot-distro Ubuntu..."
proot-distro login "$DISTRO" -- bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq \
        python3 python3-pip python3-venv \
        chromium-browser \
        libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
        libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 \
        libxrandr2 libgbm1 libasound2 libpango-1.0-0 libcairo2 \
        fonts-liberation fonts-noto-cjk \
        2>/dev/null || true
    echo '  system packages OK'
"

# ── 4. Inside proot: Python packages ────────────────────────
echo "[4/4] Installing Python packages inside proot-distro Ubuntu..."
proot-distro login "$DISTRO" -- bash -c "
    set -e

    # Ubuntu 23.04+ uses PEP 668 (externally managed). Use --break-system-packages.
    # Try with the flag first; if pip is too old to know the flag, try without.
    pip3 install --break-system-packages --quiet \
        fastapi uvicorn 'playwright>=1.40.0' pydantic 2>/dev/null \
    || pip3 install --quiet \
        fastapi uvicorn 'playwright>=1.40.0' pydantic

    # Install Playwright's ARM64 Chromium if system chromium-browser is absent
    if command -v chromium-browser &>/dev/null; then
        echo '  Using system chromium-browser'
        PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 playwright install-deps chromium 2>/dev/null || true
    else
        echo '  Downloading Playwright Chromium for ARM64 (~250 MB)...'
        playwright install chromium
        playwright install-deps chromium 2>/dev/null || true
    fi

    echo '  Python packages OK'
"

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
