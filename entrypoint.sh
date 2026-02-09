#!/bin/sh
set -e

STATE="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WS="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"

# Seed config if missing or empty
if [ ! -s "$STATE/openclaw.json" ]; then
  mkdir -p "$STATE/agents/main/agent"
  cp /seed/openclaw.json "$STATE/openclaw.json"
  cp /seed/auth-profiles.json "$STATE/agents/main/agent/auth-profiles.json"
  echo "[entrypoint] Seeded config"
fi

# Patch telegram enabled if needed
python3 -c "
import json
p = '$STATE/openclaw.json'
try:
    with open(p) as f: c = json.load(f)
    mod = False
    pe = c.setdefault('plugins',{}).setdefault('entries',{}).setdefault('telegram',{})
    if not pe.get('enabled'):
        pe['enabled'] = True; mod = True
    ch = c.setdefault('channels',{}).setdefault('telegram',{})
    if not ch.get('enabled'):
        ch['enabled'] = True; mod = True
    if mod:
        with open(p,'w') as f: json.dump(c, f, indent=2)
        print('[entrypoint] Patched telegram enabled')
except Exception as e:
    print(f'[entrypoint] Patch failed: {e}')
    import shutil; shutil.copy('/seed/openclaw.json', p)
    print('[entrypoint] Replaced with seed config')
" 2>&1 || true

# Seed workspace
if [ ! -f "$WS/SOUL.md" ]; then
  mkdir -p "$WS/memory"
  cp -r /seed/workspace/* "$WS/" 2>/dev/null || true
  echo "[entrypoint] Seeded workspace"
fi

# Execute the original CMD (passed as arguments)
exec "$@"
