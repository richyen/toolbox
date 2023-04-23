FROM centos7/postgres:13.0

# Install Yum packages
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum -y install centos-release-scl-rh && \
    yum -y groupinstall development && \
    yum -y install postgresql${PGMAJOR}-devel postgresql${PGMAJOR}-contrib llvm-devel vim git python3-devel sqlite-devel mariadb-devel

# Install mysql_fdw
RUN git clone https://github.com/enterprisedb/mysql_fdw.git && cd mysql_fdw && make USE_PGXS=1 && make USE_PGXS=1 install && cd ../

# Install sqlite_fdw
RUN git clone https://github.com/pgspider/sqlite_fdw.git && cd sqlite_fdw && make USE_PGXS=1 && make USE_PGXS=1 install && cd ../

# Install multicorn
RUN git clone https://github.com/Segfault-Inc/Multicorn.git && cd Multicorn && make && make install && cd ../

# Create extensions
RUN su - postgres -c "pg_ctl -D /var/lib/pgsql/${PGMAJOR}/data start" && \
    psql -c "create extension mysql_fdw" postgres postgres && \
    psql -c "create extension sqlite_fdw" postgres postgres && \
    psql -c "create extension multicorn" postgres postgres && \
    psql -c "CREATE SERVER mysql_server FOREIGN DATA WRAPPER mysql_fdw options (host 'mysql');" postgres postgres && \
    psql -c "CREATE USER MAPPING FOR postgres SERVER mysql_server OPTIONS (username 'root', password 'example');" postgres postgres && \
    psql -c "CREATE SERVER sqlite_server FOREIGN DATA WRAPPER sqlite_fdw options (database '/tmp/call_log.db');" postgres postgres && \
    psql -c "GRANT USAGE ON FOREIGN SERVER sqlite_server TO postgres" postgres postgres
