#!/bin/bash

IP=${1}

# verify target database connectivity
export PGPASSWORD='abc123'
psql -h ${IP} -U enterprisedb -c "select 'password worked'"

PASSWORD_HASH=`psql -h ${IP} -U enterprisedb -Atc "select passwd from pg_shadow where usename = 'enterprisedb'"`

# install pgbouncer
yum -y install pgbouncer

# configure pgbouncer
sed -e "s@^listen_addr = 127.0.0.1@listen_addr = *@g" \
 -e "s@^listen_port = [0-9]\+@listen_port = 6432@g" \
 -e "s@^auth_type = [a-zA-Z0-9]\+@auth_type = hba@g" \
 -e "s@^;auth_hba_file =@auth_hba_file = /etc/pgbouncer/bouncer_hba.conf@g" \
 -e "s@^admin_users = \(.\+\)@admin_users = \1, enterprisedb@g" \
 -e "s@^stats_users = \(.\+\)@stats_users = \1, enterprisedb@g" \
 -e "s@^pool_mode = [a-zA-Z0-9]\+@pool_mode = session@g" \
 -e "s@^max_client_conn = [0-9]\+@max_client_conn = 2000@g" \
 -i /etc/pgbouncer/pgbouncer.ini

# create databases for pgbouncer
sed "/^\[databases\]/a  prodb = host=${IP} port=5432 dbname=edb pool_size=50" -i /etc/pgbouncer/pgbouncer.ini

# create bouncer_hba
echo "host  all  all  0.0.0.0/0 trust" >> /etc/pgbouncer/bouncer_hba.conf

# set password
echo "\"enterprisedb\" \"${PASSWORD_HASH}\"" >> /etc/pgbouncer/userlist.txt

# start pgbouncer
service pgbouncer start

# test connection
psql -h 127.0.0.1 -p 6432 -U enterprisedb -d pgbouncer -c "show config" | head -n5
psql -h 127.0.0.1 -p 6432 -U enterprisedb -d prodb -c "select 1" | head -n5

# use desired mask
sed -i "s/0.0.0.0\/0/127.0.0.1\/0/" /etc/pgbouncer/bouncer_hba.conf
psql -h 127.0.0.1 -p 6432 -U enterprisedb -d pgbouncer -c "RELOAD"
sleep 5

# test connection again
psql -h 127.0.0.1 -p 6432 -U enterprisedb -d pgbouncer -c "show config" | head -n5
psql -h 127.0.0.1 -p 6432 -U enterprisedb -d prodb -c "select 1" | head -n5

# show warning/error in log
cat /var/log/pgbouncer/pgbouncer.log
