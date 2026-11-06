#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Google AI Pro — Termux/Android launcher
#
#  Runs the FastAPI server inside proot-distro Ubuntu on port 8765.
#  Open http://127.0.0.1:8765 in your phone browser after starting.
#
#  Usage (from Termux):
#    bash termux_start.sh
# ============================================================

DISTRO="ubuntu"
APP_DIR="/root/google-ai-pro"

# Keep Termux alive while server runs
termux-wake-lock 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Google AI Pro 2Year ZeroCost — Starting Server      ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Open in browser: http://127.0.0.1:8765              ║"
echo "║  Press Ctrl+C to stop                                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Check proot-distro is installed
if ! command -v proot-distro &>/dev/null; then
    echo "ERROR: proot-distro not installed. Run: bash termux_install.sh first."
    exit 1
fi

# Check app files exist — if not, try to copy from the repo dir
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROOT_ROOT=""
for TRY_PATH in \
    "$HOME/.proot-distro/$DISTRO/root" \
    "$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO/root" \
    ""; do
    if [ -n "$TRY_PATH" ] && [ -d "$TRY_PATH" ]; then
        PROOT_ROOT="$TRY_PATH"
        break
    fi
done

if [ -n "$PROOT_ROOT" ] && [ ! -f "$PROOT_ROOT/google-ai-pro/app.py" ]; then
    echo "App files not found in proot. Copying now..."
    mkdir -p "$PROOT_ROOT/google-ai-pro/templates" \
              "$PROOT_ROOT/google-ai-pro/profiles" \
              "$PROOT_ROOT/google-ai-pro/screenshots"
    cp "$SCRIPT_DIR/automation_engine.py" "$PROOT_ROOT/google-ai-pro/" 2>/dev/null || true
    cp "$SCRIPT_DIR/app.py"               "$PROOT_ROOT/google-ai-pro/" 2>/dev/null || true
    cp "$SCRIPT_DIR/templates/index.html" "$PROOT_ROOT/google-ai-pro/templates/" 2>/dev/null || true
    if [ -f "$SCRIPT_DIR/config.json" ]; then
        cp "$SCRIPT_DIR/config.json" "$PROOT_ROOT/google-ai-pro/" 2>/dev/null || true
    fi
fi

# Start the server inside proot-distro Ubuntu
proot-distro login "$DISTRO" -- bash -c "
    cd $APP_DIR
    exec python3 app.py
"
