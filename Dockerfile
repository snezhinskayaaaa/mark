FROM ghcr.io/openclaw/openclaw:latest

USER root

COPY config/openclaw.json /seed/openclaw.json
COPY config/auth-profiles.json /seed/auth-profiles.json
COPY --chmod=755 entrypoint.sh /seed/entrypoint.sh

ENTRYPOINT ["/seed/entrypoint.sh"]
