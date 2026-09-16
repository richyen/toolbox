FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HAMMERDB_VERSION=4.12

# postgresql-client lets us psql into the "pg" container for the demo;
# tclsh/libtcl is required by HammerDB's CLI (hammerdbcli).
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      tar \
      postgresql-client \
      libtcl8.6 \
      tk \
    && rm -rf /var/lib/apt/lists/*

# Fetch and unpack the official HammerDB release build
RUN curl -fsSL -o /tmp/hammerdb.tar.gz \
      "https://github.com/TPC-Council/HammerDB/releases/download/v${HAMMERDB_VERSION}/HammerDB-${HAMMERDB_VERSION}-Linux.tar.gz" \
    && mkdir -p /opt/hammerdb \
    && tar -xzf /tmp/hammerdb.tar.gz -C /opt/hammerdb --strip-components=1 \
    && rm /tmp/hammerdb.tar.gz

WORKDIR /opt/hammerdb

COPY scripts/ /opt/hammerdb/demo-scripts/

ENV PATH="/opt/hammerdb:${PATH}"
