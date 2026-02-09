#!/bin/sh
set -e

STATE="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WS="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"

# Seed config if missing or empty (first deploy or after corruption)
if [ ! -s "$STATE/openclaw.json" ]; then
  mkdir -p "$STATE/agents/main/agent"
  cp /seed/openclaw.json "$STATE/openclaw.json"
  cp /seed/auth-profiles.json "$STATE/agents/main/agent/auth-profiles.json"
  echo "[start.sh] Seeded config files"
fi

# Always force telegram plugin enabled (fixes the bug)
if command -v python3 > /dev/null 2>&1; then
  python3 -c "
import json, sys
p = '$STATE/openclaw.json'
try:
    with open(p) as f: c = json.load(f)
    changed = False
    if not c.get('plugins',{}).get('entries',{}).get('telegram',{}).get('enabled'):
        c.setdefault('plugins',{}).setdefault('entries',{}).setdefault('telegram',{})['enabled'] = True
        changed = True
    if not c.get('channels',{}).get('telegram',{}).get('enabled'):
        c.setdefault('channels',{}).setdefault('telegram',{})['enabled'] = True
        changed = True
    if changed:
        with open(p,'w') as f: json.dump(c, f, indent=2)
        print('[start.sh] Patched telegram enabled=true')
except Exception as e:
    print(f'[start.sh] Config patch failed: {e}', file=sys.stderr)
    # Replace with seed
    import shutil
    shutil.copy('/seed/openclaw.json', p)
    print('[start.sh] Replaced corrupted config with seed')
"
fi

# Seed workspace if no SOUL.md
if [ ! -f "$WS/SOUL.md" ]; then
  mkdir -p "$WS/memory"
  cp -r /seed/workspace/* "$WS/" 2>/dev/null || true
  echo "[start.sh] Seeded workspace"
fi

# Find and exec the original wrapper/entrypoint
# Railway openclaw image has a wrapper that listens on $PORT and proxies to gateway
for candidate in \
  /openclaw/docker-entry.sh \
  /openclaw/wrapper.mjs \
  /openclaw/dist/wrapper.mjs \
  /app/docker-entry.sh \
  /app/wrapper.mjs; do
  if [ -f "$candidate" ]; then
    echo "[start.sh] Exec: $candidate"
    exec node "$candidate" "$@" 2>/dev/null || exec "$candidate" "$@"
  fi
done

# Fallback: find any .mjs/.js with "wrapper" in name
WRAPPER=$(find /openclaw /app 2>/dev/null -name "*wrapper*" -type f | head -1)
if [ -n "$WRAPPER" ]; then
  echo "[start.sh] Exec wrapper: $WRAPPER"
  exec node "$WRAPPER" "$@" 2>/dev/null || exec "$WRAPPER" "$@"
fi

# Last resort: just start openclaw directly
echo "[start.sh] Fallback: openclaw gateway start"
exec openclaw gateway start --foreground --port "${PORT:-8080}"
