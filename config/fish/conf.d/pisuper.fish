# pi-super launchd service control
function pisuper-stop
    launchctl bootout "gui:(id -u)/com.foz.pi-super" 2>/dev/null; or echo "pi-super: not running"
end

function pisuper-start
    launchctl bootstrap "gui:(id -u)" ~/Library/LaunchAgents/com.foz.pi-super.plist 2>/dev/null; or echo "pi-super: already running"
end
