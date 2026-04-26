#!/bin/bash
# Read-only Mac Mini audit. Writes one report file. Modifies nothing.
# Review every line before running. Run in Terminal: bash ~/Downloads/mac-audit.sh
#
# Hardening contract:
#   - No sudo, no privilege escalation, no launchctl load/unload.
#   - No network egress (no curl, no brew update, no softwareupdate -d).
#   - No long-running captures; single-shot snapshots only.
#   - All output is redacted for common secret patterns before final write.
#   - Output file is the only thing written. umask 077 on creation.
#   - SHA-256 of the final report is printed for integrity verification.

set -u
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/Desktop/mac-audit-$TS.txt"
RAW="$(mktemp -t mac-audit-raw.XXXXXX)"
trap 'rm -f "$RAW"' EXIT

# ---------- helpers ----------

# Section banner; grep-friendly.
say() { printf '\n===== %s =====\n' "$1"; }

# `have CMD` -> 0 if present, else prints a [MISSING: CMD] marker and returns 1.
have() {
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  else
    printf '[MISSING: %s]\n' "$1"
    return 1
  fi
}

# Cap a stream at N bytes. Used to bound any section that might balloon.
# Usage:  some_command 2>&1 | cap 200000
cap() {
  local max="${1:-200000}"
  local tmp; tmp="$(mktemp -t mac-audit-cap.XXXXXX)"
  cat > "$tmp"
  local size; size=$(wc -c < "$tmp" | tr -d ' ')
  if [ "$size" -gt "$max" ]; then
    head -c "$max" "$tmp"
    printf '\n[TRUNCATED at %d bytes; section total was %d bytes]\n' "$max" "$size"
  else
    cat "$tmp"
  fi
  rm -f "$tmp"
}

# Run a command with a wall-clock timeout. Falls back to perl alarm if
# /usr/bin/timeout / gtimeout are absent (default on stock macOS).
tmo() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" "$@"
  else
    perl -e 'alarm shift; exec @ARGV' "$secs" "$@"
  fi
}

# Map permission noise to readable markers. Pipe stderr/stdout through this
# to keep the report grep-friendly.
permfilter() {
  sed -E \
    -e 's/.*Operation not permitted.*/[SIP-PROTECTED or PERMISSION-DENIED: line suppressed]/' \
    -e 's/.*not permitted.*/[PERMISSION-DENIED: line suppressed]/'
}

# Redaction pass applied to RAW before writing OUT. Patterns are conservative;
# false positives are preferable to leaking secrets. Add patterns here as new
# token shapes are encountered; do not loosen existing ones.
redact() {
  sed -E \
    -e 's/(Bearer[[:space:]]+)[A-Za-z0-9._\-]+/\1<REDACTED-BEARER>/g' \
    -e 's/sk-[A-Za-z0-9_\-]{20,}/<REDACTED-OPENAI-KEY>/g' \
    -e 's/sk-ant-[A-Za-z0-9_\-]{20,}/<REDACTED-ANTHROPIC-KEY>/g' \
    -e 's/ghp_[A-Za-z0-9]{20,}/<REDACTED-GITHUB-TOKEN>/g' \
    -e 's/gho_[A-Za-z0-9]{20,}/<REDACTED-GITHUB-OAUTH>/g' \
    -e 's/xox[abprs]-[A-Za-z0-9\-]+/<REDACTED-SLACK-TOKEN>/g' \
    -e 's/AKIA[0-9A-Z]{16}/<REDACTED-AWS-ACCESS-KEY>/g' \
    -e 's/ASIA[0-9A-Z]{16}/<REDACTED-AWS-STS-KEY>/g' \
    -e 's/AIza[0-9A-Za-z_\-]{30,}/<REDACTED-GOOGLE-API-KEY>/g' \
    -e 's/(eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.)[A-Za-z0-9_\-]{10,}/\1<REDACTED-JWT-SIG>/g' \
    -e 's/([Tt]oken|[Ss]ecret|[Pp]assword|[Aa]pi[_-]?[Kk]ey|[Aa]uth)([[:space:]]*[:=][[:space:]]*)[^[:space:]"'\'']{6,}/\1\2<REDACTED>/g'
}

# ---------- audit body ----------
# Wrapped in a brace-group so its output pipes through tee. When the pipeline
# completes, RAW is fully flushed and closed before the redaction pass reads
# it. This avoids the race that `exec > >(tee ...)` introduces on macOS bash.

{

say "Audit context"
echo "Started: $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "Host:    $(hostname)"
echo "User:    $(id -un)  (uid=$(id -u))"
echo "Output:  $OUT"
echo "Frame:   chunk 1 — hardening only; agent-identity / path / flag / Sentinel / TM / process / FDA / patch / DNS / n8n / gateway sections are added in subsequent chunks."

# Full Disk Access self-test runs near the top so the user knows up-front
# whether TCC-protected sections will be skipped further down. The actual
# TCC-dependent checks land in a later chunk; for now we just record posture.
say "Full Disk Access self-test (TCC.db readability)"
HAS_FDA=0
if [ -r "$HOME/Library/Application Support/com.apple.TCC/TCC.db" ]; then
  if command -v sqlite3 >/dev/null 2>&1; then
    if sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" 'select count(*) from access' >/dev/null 2>&1; then
      HAS_FDA=1
      echo "FDA: granted (TCC.db readable)"
    else
      echo "FDA: denied (TCC.db present but query failed)"
    fi
  else
    echo "FDA: indeterminate (sqlite3 missing)"
  fi
else
  echo "FDA: denied (TCC.db not readable from this context)"
fi
echo "HAS_FDA=$HAS_FDA"

# ---------- existing baseline sections ----------

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

say "DONE (audit body)"

} 2>&1 | tee "$RAW"

# ---------- finalization: redact, write, hash ----------

# RAW is now complete (tee child has exited). Apply redaction and write OUT.
redact < "$RAW" > "$OUT"
chmod 600 "$OUT"

HASH=""
if command -v shasum >/dev/null 2>&1; then
  HASH="$(shasum -a 256 "$OUT" | awk '{print $1}')"
fi

# Footer onto the terminal AND appended into OUT so a pasted report carries
# its own hash for verification.
{
  printf '\nReport saved to: %s\n' "$OUT"
  printf 'SHA-256: %s\n' "${HASH:-<shasum unavailable>}"
  printf 'Review %s before sharing. Redact anything you still consider sensitive.\n' "$OUT"
} | tee -a "$OUT"
