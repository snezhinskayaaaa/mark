#!/bin/sh
set -e

STATE="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WS="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"

# Fix volume permissions
mkdir -p "$STATE/agents/main/agent" "$STATE/agents/main/sessions" "$WS/memory" "$STATE/canvas" 2>/dev/null || true

# Seed config if missing
if [ ! -s "$STATE/openclaw.json" ]; then
  cp /seed/openclaw.json "$STATE/openclaw.json" 2>/dev/null || true
  cp /seed/auth-profiles.json "$STATE/agents/main/agent/auth-profiles.json" 2>/dev/null || true
  echo "[seed] Config seeded"
fi

# Patch telegram enabled
python3 -c "
import json
p = '$STATE/openclaw.json'
try:
    with open(p) as f: c = json.load(f)
    mod = False
    pe = c.setdefault('plugins',{}).setdefault('entries',{}).setdefault('telegram',{})
    if not pe.get('enabled'): pe['enabled'] = True; mod = True
    if mod:
        with open(p,'w') as f: json.dump(c, f, indent=2)
        print('[seed] Patched telegram=true')
except: pass
" 2>/dev/null || true

exec "$@"
