FROM postgres-9.4:latest
MAINTAINER richyen@yahoo.com

RUN rpm -ivh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

RUN yum -y install postgresql${PGVERNUM}-contrib.x86_64 postgis2_${PGVERNUM}

COPY install_postgis.sh /tmp/install_postgis.sh
RUN /tmp/install_postgis.sh

CMD service postgresql-${PGMAJOR} start && tail -F ${PGLOG}
