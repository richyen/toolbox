FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG DBT_KIT
ARG DBT_REF=main

RUN apt-get update && apt-get install -y --no-install-recommends \
      bc \
      build-essential \
      ca-certificates \
      cmake \
      git \
      libev-dev \
      libsqlite3-dev \
      make \
      patch \
      pkg-config \
      postgresql-common \
      sqlite3 \
    # Ubuntu's psql 16 cannot describe PostgreSQL 18 databases; use PGDG 18 client tools.
    && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y \
    && apt-get install -y --no-install-recommends \
      libpq-dev \
      postgresql-client-18 \
    && rm -rf /var/lib/apt/lists/*

# These images need the installed tools, not CPack source packages.
RUN git clone --no-checkout "https://github.com/osdldbt/${DBT_KIT}.git" /src \
    && git -C /src fetch --depth 1 origin "${DBT_REF}" \
    && git -C /src checkout --detach FETCH_HEAD \
    && sed -i '/^include (CPack)$/d' /src/CMakeLists.txt \
    && cmake -S /src -B /build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build /build --parallel \
    && cmake --install /build --prefix /usr/local \
    && rm -rf /src /build

WORKDIR /work

CMD ["bash"]
