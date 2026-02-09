#!/bin/sh
set -e

STATE="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WS="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"

# Seed config if missing or empty
if [ ! -s "$STATE/openclaw.json" ]; then
  mkdir -p "$STATE/agents/main/agent"
  cp /seed/openclaw.json "$STATE/openclaw.json"
  cp /seed/auth-profiles.json "$STATE/agents/main/agent/auth-profiles.json"
  echo "[entrypoint] Seeded config from /seed"
else
  echo "[entrypoint] Config already exists at $STATE/openclaw.json"
fi

# Ensure telegram is enabled using node (since python3 may not be available)
node -e "
const fs = require('fs');
const p = '$STATE/openclaw.json';
try {
  const c = JSON.parse(fs.readFileSync(p, 'utf8'));
  let mod = false;
  if (!c.plugins) c.plugins = {};
  if (!c.plugins.entries) c.plugins.entries = {};
  if (!c.plugins.entries.telegram) c.plugins.entries.telegram = {};
  if (!c.plugins.entries.telegram.enabled) { c.plugins.entries.telegram.enabled = true; mod = true; }
  if (!c.channels) c.channels = {};
  if (!c.channels.telegram) c.channels.telegram = {};
  if (!c.channels.telegram.enabled) { c.channels.telegram.enabled = true; mod = true; }
  if (mod) {
    fs.writeFileSync(p, JSON.stringify(c, null, 2));
    console.log('[entrypoint] Patched telegram enabled=true');
  } else {
    console.log('[entrypoint] Telegram already enabled');
  }
} catch(e) {
  console.error('[entrypoint] Patch failed:', e.message);
  const fs2 = require('fs');
  fs2.copyFileSync('/seed/openclaw.json', p);
  console.log('[entrypoint] Replaced with seed config');
}
" 2>&1 || true

# Seed workspace
if [ ! -f "$WS/SOUL.md" ]; then
  mkdir -p "$WS/memory"
  cp -r /seed/workspace/* "$WS/" 2>/dev/null || true
  echo "[entrypoint] Seeded workspace"
fi

echo "[entrypoint] Starting OpenClaw..."
# Execute the original CMD (passed as arguments)
exec "$@"
