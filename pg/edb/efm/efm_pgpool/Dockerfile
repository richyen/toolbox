FROM epas10:latest
# Get epas10:latest from https://github.com/richyen/ppas_and_docker/blob/master/epas/10/Dockerfile

# Set environment vars
ENV PGMAJOR=10
ENV SERVICE_NAME=edb-as-${PGMAJOR}
ENV EFM_VER=3.2
ENV SYSCONFDIR=/etc/sysconfig/edb/pgpool3.6/
ENV PGDATA=/var/lib/edb/as10/data

# Install packages
RUN yum -y --enablerepo=enterprisedb-tools install which edb-efm32 java-1.8.0-openjdk vim edb-pgpool36 strace

# Set up pgpool config files
COPY pgpool.conf ${SYSCONFDIR}/pgpool.conf
RUN cp ${SYSCONFDIR}/pcp.conf.sample                        ${SYSCONFDIR}/pcp.conf
RUN echo "enterprisedb:e99a18c428cb38d5f260853678922e03" >> ${SYSCONFDIR}/pcp.conf
RUN cp ${SYSCONFDIR}/pool_hba.conf.sample                   ${SYSCONFDIR}/pool_hba.conf
RUN chown -R enterprisedb:enterprisedb                      ${SYSCONFDIR}
RUN echo "172.22.77.53:9898:enterprisedb:abc123" > /tmp/.pcppass
RUN chown efm:efm /tmp/.pcppass
RUN chmod 600 /tmp/.pcppass
RUN echo "172.22.77.53:9898:enterprisedb:abc123" > /tmp/.pcppass_follow
RUN chown enterprisedb:enterprisedb /tmp/.pcppass_follow
RUN chmod 600 /tmp/.pcppass_follow

# Copy scripts
RUN mkdir -p /tmp/efm-scripts
COPY follow_master.sh /tmp/efm-scripts
COPY load_balancer_attach.sh /tmp/efm-scripts
COPY load_balancer_detach.sh /tmp/efm-scripts
COPY pgpool_backend.sh /tmp/efm-scripts
COPY post_promotion.sh /tmp/efm-scripts
RUN chown -R efm:efm /tmp/efm-scripts

# Customizations for efm/pgpool
RUN echo "wal_level = hot_standby"   >> ${PGDATA}/postgresql.conf
RUN echo "max_wal_senders = 8"       >> ${PGDATA}/postgresql.conf
RUN echo "wal_keep_segments = 100"   >> ${PGDATA}/postgresql.conf
RUN echo "max_replication_slots = 4" >> ${PGDATA}/postgresql.conf
RUN echo "hot_standby = on"          >> ${PGDATA}/postgresql.conf
RUN sed -i "s/peer/trust/"              ${PGDATA}/pg_hba.conf
RUN sed -i "s/#host/host/"              ${PGDATA}/pg_hba.conf
RUN sed -i "s/ident/trust/"             ${PGDATA}/pg_hba.conf
RUN sed -i "s/repuser/all/"             ${PGDATA}/pg_hba.conf
RUN mkdir /var/run/pgpool
RUN chmod 777 /var/run/pgpool

# Set up EFM config files
COPY efm.properties /etc/edb/efm-${EFM_VER}/efm.properties
COPY efm.nodes      /etc/edb/efm-${EFM_VER}/efm.nodes
RUN chmod 777 /etc/edb/efm-${EFM_VER}/efm.properties
RUN chmod 777 /etc/edb/efm-${EFM_VER}/efm.nodes
