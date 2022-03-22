FROM centos:7 AS pgbase

ENV PG_HOME="/usr/pgsql"
ENV PGDATA="/var/lib/pgsql/data"

RUN yum -y upgrade && \
    yum -y install epel-release && \
    yum -y groupinstall development && \
    yum -y install python3 syslog-ng git gcc readline-devel zlib-devel \
                   python3-devel crypto-devel openssl-devel libxml++-devel \
                   libxslt-devel bison-devel perl-ExtUtils-MakeMaker \
                   perl-ExtUtils-Embed pam-devel ldap-devel \
                   openldap-devel libuuid-devel uuid-devel \
                   memcached-devel memcached libmemcached-devel \
                   perl-Locale-Msgfmt.noarch tcl-devel python-devel \
                   perl-devel bison bison-runtime tar  gcc-c++ flex \
                   flex-devel libcurl-devel yum-utils libicu-devel
RUN useradd postgres
# COPY ${PATH_TO_SRC} /postgres
RUN git clone https://github.com/postgres/postgres.git

FROM pgbase

ARG COMMIT_NUM
WORKDIR /postgres

RUN git checkout ${COMMIT_NUM}
RUN /postgres/configure --prefix=${PG_HOME} --includedir=${PG_HOME}/include --mandir=${PG_HOME}/share/man \
                          --datadir=${PG_HOME}/share --with-perl --with-python --with-tcl \
                          --with-tclconfig=/usr/lib64 --with-openssl --with-pam --with-gssapi \
                          --with-includes=/usr/include --with-libraries=/usr/lib64 \
                          --with-ossp-uuid --with-libxml --with-libxslt --with-ldap --with-icu \
                          --with-system-tzdata=/usr/share/zoneinfo --sysconfdir=/etc/sysconfig/pgsql \
                          --docdir=/usr/share/doc --with-pgport=5432 --with-libmemcached --with-libcurl

RUN make && make install
RUN mkdir -p ${PGDATA} && chown postgres:postgres ${PGDATA} && chmod 700 ${PGDATA}
RUN su - postgres -c "${PG_HOME}/bin/initdb -D ${PGDATA}"

EXPOSE 5432

CMD su - postgres -c "${PG_HOME}/bin/pg_ctl -D ${PGDATA} start" && tail -f /dev/null
