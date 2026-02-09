FROM ghcr.io/openclaw/openclaw:latest

USER root

COPY config/openclaw.json /seed/openclaw.json
COPY config/auth-profiles.json /seed/auth-profiles.json
COPY workspace/ /seed/workspace/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
