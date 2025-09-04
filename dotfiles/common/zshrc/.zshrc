restart-waybar() {
    pkill -x waybar || true
    nohup waybar >/dev/null 2>&1 &
}

debug-waybar() {
    pkill -x waybar || true
    waybar
}