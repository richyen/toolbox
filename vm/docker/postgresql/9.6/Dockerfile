FROM centos:6.6
MAINTAINER richyen@yahoo.com

ENV PGMAJOR=9.6
ENV PGVERNUM=96
ENV RPM_URL=https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6-x86_64/pgdg-centos96-9.6-3.noarch.rpm

ENV PGPORT=5432
ENV PGDATABASE=postgres
ENV PGUSER=postgres
ENV PGDATA=/var/lib/pgsql/${PGMAJOR}/data
ENV PGLOG=/var/lib/pgsql/${PGMAJOR}/pgstartup.log
ENV PATH=/usr/pgsql-${PGMAJOR}/bin:${PATH}

RUN rpm -ivh ${RPM_URL}

# run update and install require packages.
RUN yum -y update
RUN yum -y install postgresql${PGVERNUM}-server.x86_64

RUN echo 'root:root'|chpasswd

# setting postgres user for login
RUN echo 'postgres   ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers
RUN echo 'postgres:postgres'|chpasswd

RUN service postgresql-${PGMAJOR} initdb

RUN echo "export PGPORT=${PGPORT}"         >> /etc/profile.d/pg_env.sh
RUN echo "export PGDATABASE=${PGDATABASE}" >> /etc/profile.d/pg_env.sh
RUN echo "export PGUSER=${PGUSER}"         >> /etc/profile.d/pg_env.sh
RUN echo "export PATH=${PATH}"             >> /etc/profile.d/pg_env.sh

RUN echo "local  all         all                 trust" >  ${PGDATA}/pg_hba.conf
RUN echo "local  replication all                 trust" >> ${PGDATA}/pg_hba.conf
RUN echo "host   replication repuser  0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
RUN echo "host   all         all      0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf

RUN sed -i "s/^#listen_addresses = 'localhost'/listen_addresses= '*'/" ${PGDATA}/postgresql.conf
RUN sed -i "s/^port = .*/port = ${PGPORT}/"         ${PGDATA}/postgresql.conf
RUN sed -i "s/^logging_collector = off/logging_collector = on/" ${PGDATA}/postgresql.conf
RUN sed -i "s/^#wal_level.*/wal_level=hot_standby/" ${PGDATA}/postgresql.conf
RUN sed -i "s/^#wal_keep_segments = 0/wal_keep_segments = 500/" ${PGDATA}/postgresql.conf
RUN sed -i "s/^#max_wal_senders = 0/max_wal_senders = 5/" ${PGDATA}/postgresql.conf

EXPOSE ${PGPORT}

CMD service postgresql-${PGMAJOR} start && tail -F ${PGLOG}
