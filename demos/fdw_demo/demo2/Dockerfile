FROM postgres:17
ENV PGMAJOR=17

# Install dependencies (Debian-based)
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        postgresql-server-dev-${PGMAJOR} \
        postgresql-contrib \
        python3 \
        python3-venv \
        python3-pip \
        llvm-dev \
        vim \
        git \
        libsqlite3-dev \
        libmariadb-dev-compat \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

# Create virtualenv for multicorn
RUN python3 -m venv /opt/venv

# Install multicorn inside venv
RUN /opt/venv/bin/pip install multicorn

# Make sure Postgres can find it
ENV PYTHONPATH="/opt/venv/lib/python3.*/site-packages"
# Install mysql_fdw
RUN git clone https://github.com/enterprisedb/mysql_fdw.git && \
    cd mysql_fdw && \
    make USE_PGXS=1 && \
    make USE_PGXS=1 install && \
    cd .. && rm -rf mysql_fdw

# Install sqlite_fdw
RUN git clone https://github.com/pgspider/sqlite_fdw.git && \
    cd sqlite_fdw && \
    make USE_PGXS=1 && \
    make USE_PGXS=1 install && \
    cd .. && rm -rf sqlite_fdw

RUN echo "shared_preload_libraries = 'multicorn'" >> /usr/share/postgresql/postgresql.conf.sample
