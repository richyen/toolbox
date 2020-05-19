FROM centos:7

ENV PGVERSION=11
ENV PGDATA="/var/lib/db"
ENV PGHOME="/var/lib/pgsql"
ENV PGINSTALL="/usr/pgsql-${PGVERSION}/bin"

RUN rpm -ivh https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
RUN yum -q -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -q -y install vim sudo postgresql${PGVERSION}-server
RUN chown -R postgres:postgres ${PGHOME}
RUN rm -rf ${PGDATA}/*
RUN mkdir -p ${PGDATA}
RUN chown postgres:postgres ${PGDATA}
RUN sudo -iu postgres ${PGINSTALL}/initdb -D ${PGDATA}
