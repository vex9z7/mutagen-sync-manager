FROM debian:bookworm-slim AS downloader

ARG MUTAGEN_VERSION=0.18.1
ARG TARGETARCH
ARG MUTAGEN_SHA256

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSL "https://github.com/mutagen-io/mutagen/releases/download/v${MUTAGEN_VERSION}/mutagen_linux_${TARGETARCH}_v${MUTAGEN_VERSION}.tar.gz" \
      -o /tmp/mutagen.tar.gz; \
    if [ -n "${MUTAGEN_SHA256:-}" ]; then \
      echo "${MUTAGEN_SHA256}  /tmp/mutagen.tar.gz" | sha256sum -c -; \
    fi; \
    mkdir -p /tmp/mutagen; \
    tar -xzf /tmp/mutagen.tar.gz -C /tmp/mutagen; \
    test -f /tmp/mutagen/mutagen; \
    test -f /tmp/mutagen/mutagen-agents.tar.gz

FROM debian:bookworm-slim

ARG MUTAGEN_UID=10001
ARG MUTAGEN_GID=10001

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gosu \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid "${MUTAGEN_GID}" mutagen \
    && useradd --uid "${MUTAGEN_UID}" --gid "${MUTAGEN_GID}" --create-home --home-dir /home/mutagen --shell /bin/sh mutagen \
    && mkdir -p /home/mutagen/.ssh /home/mutagen/.mutagen \
    && chown -R mutagen:mutagen /home/mutagen

COPY --from=downloader --chmod=755 /tmp/mutagen/ /usr/local/bin/

COPY --chmod=755 entrypoint.sh /entrypoint.sh

WORKDIR /home/mutagen

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD ["mutagen", "sync", "list"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["mutagen", "daemon", "run"]
