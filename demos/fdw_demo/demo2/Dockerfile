FROM rockylinux9/postgres:13

# Install Yum packages
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    yum -y groupinstall development && \
    yum -y install --enablerepo=devel postgresql${PGMAJOR}-devel postgresql${PGMAJOR}-contrib python3-pip llvm-devel vim git multicorn2_${PGMAJOR} sqlite-devel mariadb-devel

# Install mysql_fdw
RUN git clone https://github.com/enterprisedb/mysql_fdw.git && cd mysql_fdw && make USE_PGXS=1 && make USE_PGXS=1 install && cd ../

# Install sqlite_fdw
RUN git clone https://github.com/pgspider/sqlite_fdw.git && cd sqlite_fdw && make USE_PGXS=1 && make USE_PGXS=1 install && cd ../

# Create extensions
RUN su - postgres -c "pg_ctl -D /var/lib/pgsql/${PGMAJOR}/data start" && \
    psql -c "create extension mysql_fdw" postgres postgres && \
    psql -c "create extension sqlite_fdw" postgres postgres && \
    psql -c "create extension multicorn" postgres postgres && \
    psql -c "CREATE SERVER mysql_server FOREIGN DATA WRAPPER mysql_fdw options (host 'mysql');" postgres postgres && \
    psql -c "CREATE USER MAPPING FOR postgres SERVER mysql_server OPTIONS (username 'root', password 'example');" postgres postgres && \
    psql -c "CREATE SERVER sqlite_server FOREIGN DATA WRAPPER sqlite_fdw options (database '/tmp/call_log.db');" postgres postgres && \
    psql -c "GRANT USAGE ON FOREIGN SERVER sqlite_server TO postgres" postgres postgres
