#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Google AI Pro — Termux/Android launcher
#  Usage: bash termux_start.sh
# ============================================================

DISTRO="ubuntu"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# Check Python packages are installed inside proot
if ! proot-distro login "$DISTRO" -- python3 -c "import fastapi, uvicorn, playwright" 2>/dev/null; then
    echo "ERROR: Python packages missing inside proot. Run: bash termux_install.sh first."
    exit 1
fi

# ── Strategy: bind-mount the repo dir into proot at /google-ai-pro ──
# Try proot-distro --bind first (proot-distro >= 3.x)
# Fall back to manual copy inside proot rootfs if --bind unsupported

BIND_OK=false
proot-distro login "$DISTRO" --bind "$SCRIPT_DIR:/google-ai-pro" -- bash -c "test -f /google-ai-pro/app.py" 2>/dev/null && BIND_OK=true

if $BIND_OK; then
    echo "App dir: $SCRIPT_DIR (bind-mounted)"
    exec proot-distro login "$DISTRO" \
        --bind "$SCRIPT_DIR:/google-ai-pro" \
        -- bash -c "
            cd /google-ai-pro
            mkdir -p profiles screenshots
            exec python3 app.py
        "
else
    # Fallback: find proot rootfs and copy files there
    echo "proot-distro --bind not supported, copying files..."
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
        # Last resort: ask proot-distro where the rootfs is
        PROOT_ROOT=$(proot-distro login "$DISTRO" -- bash -c "echo /root" 2>/dev/null || echo "")
        # Can't determine path — let user know
        echo "ERROR: Cannot determine proot rootfs path."
        echo "Please run manually:"
        echo "  proot-distro login ubuntu"
        echo "  mkdir -p /root/google-ai-pro/templates"
        echo "  cp (your repo path)/app.py /root/google-ai-pro/"
        echo "  cp (your repo path)/automation_engine.py /root/google-ai-pro/"
        echo "  cp (your repo path)/templates/index.html /root/google-ai-pro/templates/"
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
        cd /root/google-ai-pro
        exec python3 app.py
    "
fi
