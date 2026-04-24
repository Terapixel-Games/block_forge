FROM ubuntu:24.04

ARG GODOT_VERSION=4.5.1
ARG GODOT_STATUS=stable

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget unzip bash \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    GODOT_BASE="Godot_v${GODOT_VERSION}-${GODOT_STATUS}"; \
    HEADLESS_ZIP="${GODOT_BASE}_linux.x86_64.zip"; \
    wget -O /tmp/godot.zip "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_STATUS}/${HEADLESS_ZIP}"; \
    unzip -o /tmp/godot.zip -d /opt/godot; \
    mv "/opt/godot/${GODOT_BASE}_linux.x86_64" /usr/local/bin/godot; \
    chmod +x /usr/local/bin/godot

WORKDIR /workspace
