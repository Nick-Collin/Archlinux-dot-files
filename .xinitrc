# ====== Environment Setup ======
# Set XDG desktop identifier (helps apps like Firefox/GTK use proper theming)
export XDG_CURRENT_DESKTOP="DWM"

# Force cursor theme (prevents invisible cursor on some systems)
xsetroot -cursor_name left_ptr  # left_ptr = standard arrow cursor

# ====== Background Services ======
# Start status bar (shows system info in dwm's bar)
slstatus &  # & runs process in background

# Auto-display configuration (for multi-monitor setups)
autorandr -c &  # -c = apply first matching config

# Disk automount daemon (tray icon for USB drives)
udiskie -t &  # -t = show tray icon

# Compositor for transparency/effects (daemon mode with logging)
picom --daemon --log-file ~/.picom.log &  # Logs help diagnose rendering issues

# ====== Display Configuration ======
# Group commands in {} for error handling
{
    # Set primary display resolution (laptop screen)
    xrandr --output eDP-1 --mode 1366x768
    
    # Check if HDMI connected (grep -q = quiet mode)
    xrandr --query | grep -q "HDMI-1 connected" && \
    # If HDMI found, set to right of primary display
    xrandr --output HDMI-1 --auto --right-of eDP-1
} || echo "Display configuration failed" >&2  # || = run if previous command fails

# ====== Wallpaper System ======
# Background process to set wallpaper after 1sec delay
{
    sleep 1  # Wait for display initialization
    feh --bg-fill ~/Pictures/Wallpapers/Default  # --bg-fill = scale to fill screen
} &  # & makes this run in background

# ====== Dynamic Wallpaper Watcher ======
# Check if inotifywait exists in system PATH
if command -v inotifywait >/dev/null; then
    # Start subshell ( ) for isolated process
    (
        # Infinite loop: monitor wallpaper directory
        while inotifywait -r -q -e close_write,delete ~/Pictures/Wallpapers/; do
            # On change: set random wallpaper
            feh --bg-fill ~/Pictures/Wallpapers/$(ls ~/Pictures/Wallpapers/ | shuf -n1)
            # shuf -n1 = pick random file, $( ) = command substitution
        done
    ) &  # Run watcher in background
else
    echo "inotify-tools not installed" >&2  # >&2 = write to stderr
fi

# ====== Window Manager ======
DWM_BIN="$HOME/WindowMngr/dwm/build/bin/dwm"
DWM_BAK="$HOME/WindowMngr/dwm/build/bin/dwm.bak"
CRASH_LOG="$HOME/.dwm_crash.log"

# Ensure backup exists
if [ ! -f "$DWM_BAK" ]; then
    cp "$DWM_BIN" "$DWM_BAK"
fi

while :; do
    exec "$DWM_BIN" > ~/.dwm.log 2>&1

    STATUS=$?

    # Exit code 0 means dwm exited cleanly (e.g. you quit manually or restarted internally)
    if [ $STATUS -eq 0 ]; then
        break
    fi

    # Non-zero means a crash; fall back to backup
    echo "$(date '+%Y-%m-%d %H:%M:%S') - dwm crashed with status $STATUS" >> "$CRASH_LOG"
    if [ -f "$DWM_BAK" ]; then
        cp "$DWM_BAK" "$DWM_BIN"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Reverted to backup dwm binary" >> "$CRASH_LOG"
    fi

    # Avoid crash loops
    sleep 1
done

