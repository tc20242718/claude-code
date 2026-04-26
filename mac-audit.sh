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

# ---------- gap sections (chunks 2+) ----------

# Gap 1 — Binary identity for the named agents.
# Distinguishes Mach-O binary vs shell script vs symlink vs absent. Records
# signing identity, team ID, entitlements, hash. Anything claimed by the
# v3.2/v3.3 guides as "an installed agent" must show up here with evidence
# or the claim is refuted.
say "Gap 1 — Binary identity for named agents"
AGENT_BINS="openclaw nanoclaw nemoclaw sentinel sentinelctl claw codex ollama claude"
for bin in $AGENT_BINS; do
  echo "--- $bin"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "[ABSENT: $bin not on PATH]"
    # Still scan a few common install dirs in case it's installed but unlinked.
    for dir in /usr/local/bin /opt/homebrew/bin /opt/local/bin "$HOME/.local/bin" "$HOME/bin"; do
      if [ -e "$dir/$bin" ]; then
        echo "[NOTE: $dir/$bin exists but not on PATH]"
      fi
    done
    continue
  fi
  # All resolved paths (which -a shows shadowed copies; matters for PATH-poisoning).
  echo "which -a:"
  which -a "$bin" 2>/dev/null | sed 's/^/  /'
  resolved="$(command -v "$bin")"
  # Resolve symlinks fully so signing/hashing applies to the real target.
  if command -v readlink >/dev/null 2>&1; then
    real="$(readlink -f "$resolved" 2>/dev/null || echo "$resolved")"
  else
    real="$resolved"
  fi
  echo "resolved: $resolved"
  echo "real:     $real"
  if [ -e "$real" ]; then
    file "$real" 2>/dev/null | sed 's/^/  /'
    stat -f 'mode=%Sp uid=%Su gid=%Sg size=%z mtime=%Sm' "$real" 2>/dev/null \
      || stat "$real" 2>/dev/null
    if command -v shasum >/dev/null 2>&1; then
      shasum -a 256 "$real" 2>/dev/null | sed 's/^/  sha256: /'
    fi
    # Code signing — only meaningful for Mach-O. Will print "not signed at all"
    # for shell scripts; that's diagnostic, not noise.
    echo "codesign:"
    codesign -dvvv --entitlements - -- "$real" 2>&1 | cap 8000 | sed 's/^/  /'
  else
    echo "[STALE: $resolved is on PATH but the file doesn't exist]"
  fi
done

# Gap 2 — Literal path-existence loop for v3.2/v3.3 guide claims.
# Iterates every path the guides assert. Each row is present/absent, with
# size and mtime when present. Output of this section is the input to the
# claim-vs-evidence table that gates v3.4.
say "Gap 2 — Path-claim verification (v3.2 / v3.3 asserted paths)"
GUIDE_PATHS=(
  "$HOME/Library/Containers/com.openai.codex"
  "$HOME/Library/Preferences/com.openclaw.plist"
  "$HOME/Library/Preferences/com.nanoclaw.plist"
  "$HOME/Library/Preferences/com.sentinel.plist"
  "$HOME/Library/Application Support/OpenClaw"
  "$HOME/Library/Application Support/NanoClaw"
  "$HOME/Library/Application Support/Sentinel"
  "$HOME/Library/Application Support/Codex"
  "$HOME/Library/Application Support/Claude"
  "$HOME/Library/Group Containers"
  "/Library/Application Support/Sentinel"
  "/Library/Application Support/OpenClaw"
  "/Library/Application Support/NanoClaw"
  "/Applications/OpenClaw.app"
  "/Applications/NanoClaw.app"
  "/Applications/NemoClaw.app"
  "/Applications/Sentinel.app"
  "/Applications/SentinelOne.app"
  "/Applications/Codex.app"
  "/Applications/Claude.app"
  "$HOME/.openclaw/openclaw.json"
  "$HOME/.openclaw/config.json"
  "$HOME/.nanoclaw/config.json"
  "$HOME/.codex/config.toml"
  "$HOME/.claude/settings.json"
  "$HOME/.claude/CLAUDE.md"
  "$HOME/.claude/active-work.md"
)
for p in "${GUIDE_PATHS[@]}"; do
  if [ -e "$p" ]; then
    if [ -d "$p" ]; then
      kind="dir"
    elif [ -L "$p" ]; then
      kind="symlink"
    else
      kind="file"
    fi
    sz="$(stat -f '%z' "$p" 2>/dev/null || echo '?')"
    mt="$(stat -f '%Sm' "$p" 2>/dev/null || echo '?')"
    printf 'PRESENT  %-7s  size=%s  mtime=%s  %s\n' "$kind" "$sz" "$mt" "$p"
  else
    # Group Containers is a parent dir; if absent, skip noisily but match its
    # children pattern when present. Handled below for that one row.
    printf 'absent                                          %s\n' "$p"
  fi
done
# Group Containers: if the parent exists, list any *claw* match.
if [ -d "$HOME/Library/Group Containers" ]; then
  echo "-- Group Containers / *claw* matches:"
  find "$HOME/Library/Group Containers" -maxdepth 1 -iname '*claw*' 2>/dev/null \
    | head -20 | sed 's/^/  /' || echo "  (none)"
fi

# Gap 3 — Command-flag verification with isolated HOME.
# The v3.2/v3.3 guides claim flags like --preserve-channels and a
# `verify-channels` subcommand. The only honest check is to ask the binary
# itself, with HOME redirected so help text cannot mutate real config and a
# 3-second cap so a misbehaving binary cannot hang the audit.
say "Gap 3 — Command flag verification (--help / --version, isolated HOME, 3s cap)"
ISO_HOME="$(mktemp -d -t mac-audit-iso-home.XXXXXX)"
trap 'rm -f "$RAW"; rm -rf "$ISO_HOME"' EXIT
echo "isolated HOME: $ISO_HOME"
for bin in $AGENT_BINS; do
  command -v "$bin" >/dev/null 2>&1 || continue
  echo "--- $bin --version"
  HOME="$ISO_HOME" tmo 3 "$bin" --version 2>&1 | cap 4000 | sed 's/^/  /'
  echo "  exit=${PIPESTATUS[0]} (124 = timed out)"
  echo "--- $bin --help"
  HOME="$ISO_HOME" tmo 3 "$bin" --help 2>&1 | cap 8000 | sed 's/^/  /'
  echo "  exit=${PIPESTATUS[0]} (124 = timed out)"
done

# Gap 4 — Sentinel disambiguation.
# "Sentinel" is ambiguous: it could be SentinelOne EDR, an Apple endpoint
# protection, a plugin, or a custom user script. This section forces one
# of [SentinelOne / Apple Endpoint Security client / not found / custom
# user script] by checking the surfaces each would register on.
say "Gap 4 — Sentinel disambiguation"

echo "-- systemextensionsctl list (system extensions registered with the kernel)"
if have systemextensionsctl; then
  tmo 5 systemextensionsctl list 2>&1 | cap 50000
fi

echo "-- pluginkit -mAvvv | (filter to security/endpoint relevant)"
if have pluginkit; then
  tmo 5 pluginkit -mAvvv 2>&1 \
    | grep -iE 'sentinel|crowdstrike|sophos|carbonblack|jamf|endpoint|security' \
    | cap 30000 \
    || echo "(no matching pluginkit entries)"
fi

echo "-- /Applications and /Library matches for Sentinel-named bundles"
ls -ld /Applications/SentinelOne* 2>/dev/null || true
ls -ld /Applications/Sentinel* 2>/dev/null || true
ls -ld "/Library/Sentinel"* 2>/dev/null || true
ls -ld "/Library/Application Support/SentinelOne" 2>/dev/null || true
ls -ld "/Library/Application Support/Sentinel"* 2>/dev/null || true

echo "-- launchctl list filtered to known EDR / endpoint vendor names"
if have launchctl; then
  tmo 5 launchctl list 2>&1 \
    | grep -iE 'sentinel|sentinelone|endpoint|crowdstrike|sophos|jamf|carbonblack|falcon' \
    | cap 20000 \
    || echo "(no matching launchctl entries — Sentinel not running as managed service for this user)"
fi

echo "-- MDM enrollment posture (profiles list / show -type enrollment)"
if have profiles; then
  tmo 5 profiles list 2>&1 | cap 30000
  echo "-- profiles show -type enrollment"
  tmo 5 profiles show -type enrollment 2>&1 | cap 10000
fi

echo "-- Sentinel disambiguation summary heuristic"
# Best-effort classification based on what we just saw. This is a hint only;
# the user/analyst confirms by reading the raw evidence above.
sentinel_class="unknown"
if ls -d /Applications/SentinelOne* >/dev/null 2>&1; then
  sentinel_class="SentinelOne EDR (vendor app present in /Applications)"
elif systemextensionsctl list 2>/dev/null | grep -qi sentinel; then
  sentinel_class="System extension named 'sentinel' is registered (kind unclear — inspect bundle ID above)"
elif command -v sentinel >/dev/null 2>&1; then
  sentinel_class="A 'sentinel' binary is on PATH but no SentinelOne app or system extension found — likely custom user script (verify with Gap 1 binary identity above)"
else
  sentinel_class="Not found — no SentinelOne, no system extension, no binary on PATH. v3.2/v3.3 'Sentinel' references are unsupported."
fi
echo "Sentinel-class: $sentinel_class"

# Gap 5 — Endpoint Security client registrations.
# Cross-checks Gap 4 by hunting for *.systemextension bundles in the standard
# install locations. ES clients live here regardless of vendor; their
# presence answers "is anything actually using the Endpoint Security API?"
say "Gap 5 — Endpoint Security registrations (*.systemextension bundles)"
echo "-- /Library/SystemExtensions"
if [ -d /Library/SystemExtensions ]; then
  find /Library/SystemExtensions -maxdepth 4 -type d -name '*.systemextension' 2>&1 \
    | permfilter | cap 20000
else
  echo "(no /Library/SystemExtensions directory)"
fi
echo "-- /Applications/*/Contents/Library/SystemExtensions"
find /Applications -maxdepth 5 -path '*/Contents/Library/SystemExtensions/*.systemextension' 2>&1 \
  | permfilter | cap 20000 \
  || echo "(none found)"

# Gap 6 — Time Machine destination encryption.
# v3.2/v3.3 implied that Time Machine is in use; the actual question is
# whether the destination volume is encrypted (so backups don't leak the
# secrets the rest of the host protects).
say "Gap 6 — Time Machine destination encryption"
if have tmutil; then
  echo "-- tmutil destinationinfo -X (raw plist)"
  tmo 5 tmutil destinationinfo -X 2>&1 | cap 20000
  echo "-- tmutil destinationinfo (parsed Encryption / Kind / Name lines)"
  tmo 5 tmutil destinationinfo 2>&1 \
    | grep -iE 'name|kind|encryption|mountpoint|id ' \
    | cap 5000 \
    || echo "(tmutil produced no Encryption line — destination may be unencrypted, missing, or unconfigured)"
fi
echo "-- diskutil apfs list (cross-check: is the destination volume itself encrypted?)"
if have diskutil; then
  tmo 8 diskutil apfs list 2>&1 \
    | grep -E 'Volume|Encrypted|FileVault|Mount Point|APFS Volume Disk' \
    | cap 20000
fi

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
