FROM ghcr.io/openclaw/openclaw:latest

# Store seed files in image (will be copied to volume at runtime)
COPY config/openclaw.json /seed/openclaw.json
COPY config/auth-profiles.json /seed/auth-profiles.json
COPY workspace/ /seed/workspace/

# Wrap the original entrypoint: rename it, put our script in its place
# The image likely uses CMD or ENTRYPOINT with the wrapper script
# We'll use a shell wrapper that seeds then exec's the original process
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Don't override CMD — just set our entrypoint which will exec "$@" (original CMD)
ENTRYPOINT ["/entrypoint.sh"]
