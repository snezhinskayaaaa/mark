FROM ghcr.io/openclaw/openclaw:latest

# Store seed files in image
COPY config/openclaw.json /seed/openclaw.json
COPY config/auth-profiles.json /seed/auth-profiles.json
COPY workspace/ /seed/workspace/
COPY start.sh /seed/start.sh
RUN chmod +x /seed/start.sh

# Use our script as entrypoint; it seeds files then execs the original process
ENTRYPOINT ["/seed/start.sh"]
