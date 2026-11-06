#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Google AI Pro — Termux/Android launcher
#  Usage: bash termux_start.sh
# ============================================================

DISTRO="ubuntu"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV=/root/venv-google-ai

termux-wake-lock 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Google AI Pro 2Year ZeroCost — Starting Server      ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Open in browser: http://127.0.0.1:8765              ║"
echo "║  Press Ctrl+C to stop                                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

if ! command -v proot-distro &>/dev/null; then
    echo "ERROR: proot-distro not installed. Run: bash termux_install.sh first."
    exit 1
fi

# Check the venv exists (created by termux_install.sh)
proot-distro login "$DISTRO" -- test -f "$VENV/bin/activate" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: venv not found inside proot ($VENV). Run: bash termux_install.sh first."
    exit 1
fi

echo "App dir : $SCRIPT_DIR"
echo "Venv    : $VENV (inside proot)"
echo ""

# ── Try --bind first (proot-distro >= 3.x) ──────────────────
BIND_OK=false
proot-distro login "$DISTRO" --bind "$SCRIPT_DIR:/google-ai-pro" \
    -- test -f /google-ai-pro/app.py 2>/dev/null && BIND_OK=true

if $BIND_OK; then
    exec proot-distro login "$DISTRO" \
        --bind "$SCRIPT_DIR:/google-ai-pro" \
        -- bash -c "
            source $VENV/bin/activate
            cd /google-ai-pro
            mkdir -p profiles screenshots
            exec python3 app.py
        "
else
    # ── Fallback: copy files into proot rootfs ───────────────
    echo "proot-distro --bind not available, copying files..."
    PROOT_ROOT=""
    for TRY in \
        "$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO/root" \
        "$HOME/.proot-distro/$DISTRO/root"; do
        if [ -d "$TRY" ]; then
            PROOT_ROOT="$TRY"
            break
        fi
    done

    if [ -z "$PROOT_ROOT" ]; then
        echo "ERROR: Cannot find proot rootfs path."
        echo "Please open a proot shell manually:"
        echo "  proot-distro login ubuntu"
        echo "  mkdir -p /root/google-ai-pro/templates"
        echo "  cp $SCRIPT_DIR/app.py /root/google-ai-pro/"
        echo "  cp $SCRIPT_DIR/automation_engine.py /root/google-ai-pro/"
        echo "  cp $SCRIPT_DIR/templates/index.html /root/google-ai-pro/templates/"
        echo "  source $VENV/bin/activate && python3 /root/google-ai-pro/app.py"
        exit 1
    fi

    APP_DST="$PROOT_ROOT/google-ai-pro"
    mkdir -p "$APP_DST/templates" "$APP_DST/profiles" "$APP_DST/screenshots"
    cp "$SCRIPT_DIR/automation_engine.py" "$APP_DST/"
    cp "$SCRIPT_DIR/app.py"               "$APP_DST/"
    cp "$SCRIPT_DIR/templates/index.html" "$APP_DST/templates/"
    [ -f "$SCRIPT_DIR/config.json" ] && cp "$SCRIPT_DIR/config.json" "$APP_DST/" || true
    echo "Files copied to $APP_DST"

    exec proot-distro login "$DISTRO" -- bash -c "
        source $VENV/bin/activate
        cd /root/google-ai-pro
        exec python3 app.py
    "
fi
