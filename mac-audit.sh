#!/bin/bash
# Read-only Mac Mini audit. Writes one report file. Modifies nothing.
# Review every line before running. Run in Terminal: bash ~/Downloads/mac-audit.sh

set -u
OUT="$HOME/Desktop/mac-audit-$(date +%Y%m%d-%H%M%S).txt"
exec > >(tee "$OUT") 2>&1

say() { printf '\n===== %s =====\n' "$1"; }

say "macOS + hardware"
sw_vers
uname -a
sysctl -n machdep.cpu.brand_string 2>/dev/null || true

say "Security posture"
csrutil status 2>/dev/null || echo "csrutil: n/a"
fdesetup status 2>/dev/null || echo "fdesetup: n/a"
spctl --status 2>/dev/null || echo "spctl: n/a"
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || true

say "XProtect / MRT versions"
defaults read /Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "XProtect: n/a"

say "Logged-in user context"
id
groups
echo "SHELL=$SHELL"

say "Home dir inventory (names only, no contents)"
for d in ".openclaw" ".ollama" ".nanoclaw" ".codex" ".claude" ".config/claude"; do
  p="$HOME/$d"
  if [ -e "$p" ]; then
    echo "-- $p"
    ls -la "$p" 2>/dev/null | head -50
  else
    echo "-- $p : absent"
  fi
done

say "Application Support candidates"
for d in "Codex" "Claude" "Ollama" "OpenClaw" "NanoClaw" "Sentinel"; do
  p="$HOME/Library/Application Support/$d"
  [ -e "$p" ] && { echo "-- $p"; ls -la "$p" | head -20; } || echo "-- $p : absent"
done

say "Installed .app bundles matching agent names"
find /Applications "$HOME/Applications" -maxdepth 2 -type d -name "*.app" 2>/dev/null \
  | grep -iE 'claude|codex|ollama|openclaw|nanoclaw|sentinel|claw' || echo "none"

say "Code signing + notarization status of found apps"
while IFS= read -r app; do
  [ -z "$app" ] && continue
  echo "--- $app"
  codesign -dv --verbose=2 "$app" 2>&1 | grep -E 'Authority|TeamIdentifier|Identifier|Format' || true
  spctl --assess --type execute --verbose "$app" 2>&1 || true
done < <(find /Applications "$HOME/Applications" -maxdepth 2 -type d -name "*.app" 2>/dev/null \
  | grep -iE 'claude|codex|ollama|openclaw|nanoclaw|sentinel|claw')

say "LaunchAgents / LaunchDaemons referencing these tools"
for dir in "$HOME/Library/LaunchAgents" "/Library/LaunchAgents" "/Library/LaunchDaemons"; do
  [ -d "$dir" ] || continue
  grep -liE 'openclaw|nanoclaw|ollama|codex|claude|sentinel' "$dir"/*.plist 2>/dev/null || true
done

say "Listening network sockets (agent-relevant only)"
lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null \
  | awk 'NR==1 || /ollama|openclaw|nanoclaw|codex|claude|sentinel|node|python/' \
  | head -40

say "Keychain items that look like bot tokens (names only, NO secrets printed)"
security dump-keychain 2>/dev/null \
  | awk '/"svce"/{s=$0} /"acct"/{a=$0; print s "  |  " a}' \
  | grep -iE 'telegram|discord|slack|openclaw|nanoclaw|bot|anthropic|openai' \
  | head -40 || echo "none matched"

say "Shell rc files — agent-related lines only (tokens redacted)"
for f in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  [ -f "$f" ] || continue
  echo "-- $f"
  grep -nE 'OPENCLAW|NANOCLAW|OLLAMA|CODEX|CLAUDE|ANTHROPIC|TELEGRAM|DISCORD|SLACK|TOKEN|API_KEY' "$f" 2>/dev/null \
    | sed -E 's/(=|: *)[^ ]+/\1<REDACTED>/' || true
done

say "Homebrew packages relevant to agents"
if command -v brew >/dev/null 2>&1; then
  brew list --versions 2>/dev/null | grep -iE 'ollama|python|node|docker|colima|podman' || true
else
  echo "brew: not installed"
fi

say "Docker / container state (if present)"
command -v docker >/dev/null && docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null || echo "docker: not running or absent"

say "Recently modified files in agent dirs (last 7 days, names only)"
for d in "$HOME/.openclaw" "$HOME/.ollama" "$HOME/.nanoclaw" "$HOME/.codex" "$HOME/.claude"; do
  [ -d "$d" ] || continue
  find "$d" -type f -mtime -7 2>/dev/null | head -30
done

say "DONE"
echo "Report saved to: $OUT"
echo "Review it before sharing. Redact anything you consider sensitive."
