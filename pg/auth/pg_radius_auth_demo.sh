#!/bin/bash

# Demo script to set up RADIUS authentication on PG 9.x on Centos 6
# If using a later version of CentOS, you may need to use /etc/raddb/mods-config/files/authorize
# Derived from steps shared by Gowtham Kumar

# install and test freeradius

yum -y install freeradius-utils
printf "steve Cleartext-Password := \"testing\" \n
              Service-Type = Framed-User, \n
              Framed-Protocol = PPP, \n
              Framed-IP-Address = 172.16.3.33, \n
              Framed-IP-Netmask = 255.255.255.0, \n
              Framed-Routing = Broadcast-Listen, \n
              Framed-Filter-Id = \"std.ppp\", \n
              Framed-MTU = 1500, \n
              Framed-Compression = Van-Jacobsen-TCP-IP\n" >> /etc/raddb/users
/etc/init.d/radiusd start
radtest steve testing 127.0.0.1 0 testing123


# test on postgres

psql -c "CREATE USER steve WITH PASSWORD 'foobar'"
sed -i "s/host   all.*trust/host   all         all      0.0.0.0\/0  radius  radiusserver=127.0.0.1 radiussecret=testing123 radiusport=1812/" /var/lib/pgsql/9.5/data/pg_hba.conf
psql -c "select pg_reload_conf()"

# Log in with wrong RADIUS password
set -x
PGPASSWORD='foobar' psql -d postgres -U steve -h 127.0.0.1
# Log in with correct RADIUS password
PGPASSWORD='testing' psql -d postgres -U steve -h 127.0.0.1
