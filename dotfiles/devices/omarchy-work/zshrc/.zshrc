restart-waybar() {
    pkill -f waybar || true
    nohup waybar >/dev/null 2>&1 &
}