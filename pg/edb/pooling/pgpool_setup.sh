#!/bin/bash

# Add the repo
yum -y install http://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm

# export YUMUSERNAME=
# export YUMPASSWORD=

sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/g"        /etc/yum.repos.d/edb.repo
sed -i "\/edbas96/,/gpgcheck/ s/enabled=0/enabled=1/"                   /etc/yum.repos.d/edb.repo
sed -i "\/enterprisedb-dependencies/,/gpgcheck/ s/enabled=0/enabled=1/" /etc/yum.repos.d/edb.repo
sed -i "\/enterprisedb-tools/,/gpgcheck/ s/enabled=0/enabled=1/"        /etc/yum.repos.d/edb.repo

# Install EDBAS
yum -y install edb-as96-server

/usr/edb/as9.6/bin/edb-as-96-setup initdb

# Create secondary service script for standby node
cp /usr/lib/systemd/system/edb-as-9.6.service /usr/lib/systemd/system/secondary-edb-as-9.6.service
sed -i "s/\/data/\/data_too/" /usr/lib/systemd/system/secondary-edb-as-9.6.service

systemctl enable edb-as-9.6 secondary-edb-as-9.6

PGDATA1=`cat /usr/lib/systemd/system/edb-as-9.6.service  | grep "Environment=PGDATA" | sed "s/.*PGDATA=//"`
PGDATA2=`cat /usr/lib/systemd/system/secondary-edb-as-9.6.service  | grep "Environment=PGDATA" | sed "s/.*PGDATA=//"`

# Customizations for replication
echo "wal_level = hot_standby"   >> ${PGDATA1}/postgresql.conf
echo "max_wal_senders = 8"       >> ${PGDATA1}/postgresql.conf
echo "wal_keep_segments = 100"   >> ${PGDATA1}/postgresql.conf
echo "max_replication_slots = 4" >> ${PGDATA1}/postgresql.conf
echo "hot_standby = on"          >> ${PGDATA1}/postgresql.conf
sed -i "s/peer/trust/"              ${PGDATA1}/pg_hba.conf
sed -i "s/#host/host/"              ${PGDATA1}/pg_hba.conf
sed -i "s/ident/trust/"             ${PGDATA1}/pg_hba.conf

systemctl start edb-as-9.6

# Set up replication
/usr/edb/as9.6/bin/psql -c "ALTER USER enterprisedb WITH password 'enterprisedb'" template1 enterprisedb
/usr/edb/as9.6/bin/psql -c "ALTER USER enterprisedb WITH replication" template1 enterprisedb
/usr/edb/as9.6/bin/pg_basebackup -h 127.0.0.1 -p 5444 -U enterprisedb -D ${PGDATA2} -R
sed -i "s/port =.*/port = 5445/"    ${PGDATA2}/postgresql.conf
chown -R enterprisedb:enterprisedb  ${PGDATA2}
systemctl start secondary-edb-as-9.6

# Install pgpool
yum -y install edb-pgpool36.x86_64

# Configure pgpool
SYSCONFDIR=/etc/sysconfig/edb/pgpool3.6/
cp ${SYSCONFDIR}/pcp.conf.sample      ${SYSCONFDIR}/pcp.conf
cp ${SYSCONFDIR}/pool_hba.conf.sample ${SYSCONFDIR}/pool_hba.conf
cp ${SYSCONFDIR}/pgpool.conf.sample   ${SYSCONFDIR}/pgpool.conf

sed -i "s/listen_addresses = 'localhost'/listen_addresses = '*'/" ${SYSCONFDIR}/pgpool.conf
sed -i "s/listen_addresses = 'localhost'/listen_addresses = '*'/" ${SYSCONFDIR}/pgpool.conf
sed -i "s/hostname0 = 'localhost'/hostname0 = '127.0.0.1'/"       ${SYSCONFDIR}/pgpool.conf
sed -i "s/as10/as9.6/"                                            ${SYSCONFDIR}/pgpool.conf
sed -i "s/enable_pool_hba = off/enable_pool_hba = on/"            ${SYSCONFDIR}/pgpool.conf
sed -i "s/master_slave_mode = off/master_slave_mode = on/"        ${SYSCONFDIR}/pgpool.conf
sed -i "s/sub_mode.*/sub_mode = stream/"                          ${SYSCONFDIR}/pgpool.conf
sed -i "s/load_balance_mode = off/load_balance_mode = on/"        ${SYSCONFDIR}/pgpool.conf
echo "backend_hostname1 = '127.0.0.1'"        >> ${SYSCONFDIR}/pgpool.conf
echo "backend_port1 = 5445"                   >> ${SYSCONFDIR}/pgpool.conf
echo "backend_weight1 = 1"                    >> ${SYSCONFDIR}/pgpool.conf
echo "backend_data_directory1 = '${PGDATA2}'" >> ${SYSCONFDIR}/pgpool.conf
echo "backend_flag1 = 'ALLOW_TO_FAILOVER'"    >> ${SYSCONFDIR}/pgpool.conf

echo "enterprisedb:md500c96db122dd14db6e37dbd174dc51ef" >> ${SYSCONFDIR}/pcp.conf
echo "enterprisedb:md500c96db122dd14db6e37dbd174dc51ef" >> ${SYSCONFDIR}/pool_passwd

chown -R enterprisedb:enterprisedb  ${SYSCONFDIR}
systemctl start edb-pgpool-3.6
