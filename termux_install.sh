#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Google AI Pro — Termux/Android installer
#  Usage: bash termux_install.sh
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
proot-distro login "$DISTRO" -- bash << 'PROOT_SYS'
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
echo "  system packages OK"
PROOT_SYS

# ── 4. Inside proot: Python packages via venv ───────────────
echo "[4/4] Installing Python packages inside proot-distro Ubuntu..."
proot-distro login "$DISTRO" -- bash << 'PROOT_PY'
set -e

VENV=/root/venv-google-ai

# Create venv — this gives us a fresh pip that understands manylinux_2_17_aarch64
python3 -m venv "$VENV"
source "$VENV/bin/activate"

# Upgrade pip inside the venv (safe — does not touch system pip)
pip install --quiet --upgrade pip

# Install packages
echo "  Installing fastapi, uvicorn, playwright, pydantic..."
pip install --quiet fastapi uvicorn "playwright>=1.40.0" pydantic

# Debug: show what platform pip detected
echo "  pip platform: $(python3 -c 'import pip._internal.utils.compatibility_tags as t; print(list(t.get_supported())[0])'  2>/dev/null || echo 'unknown')"
echo "  playwright version: $(pip show playwright | grep ^Version)"

# Install Chromium — prefer system, fallback to playwright's
if command -v chromium-browser &>/dev/null; then
    echo "  Using system chromium-browser"
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 playwright install-deps chromium 2>/dev/null || true
else
    echo "  Downloading Playwright Chromium for ARM64 (~250 MB)..."
    playwright install chromium
    playwright install-deps chromium 2>/dev/null || true
fi

echo "  Python packages OK — venv at $VENV"
PROOT_PY

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Installation complete!                              ║"
echo "║                                                      ║"
echo "║  To start the server:                                ║"
echo "║    bash termux_start.sh                              ║"
echo "║                                                      ║"
echo "║  Then open in your phone browser:                   ║"
echo "║    http://127.0.0.1:8765                             ║"
echo "╚══════════════════════════════════════════════════════╝"
