#!/bin/bash

PGDATA=/var/lib/pgsql/12/data
### Install Kerberos & dependencies:

yum install readline readline-devel zlib zlib-devel gcc krb5-server krb5-libs krb5-workstation pam_krb5 krb5-auth-dialog krb5-devel
su - postgres -c "pg_ctl -D ${PGDATA} -l /tmp/logfile start"

# 1. Configure Kerberos and validate Kerberos authentication with postgresql via psql

# Server-side setup(needs to be done using root user)
# Add host entry

echo $( hostname -i ) myrealm.example >> /etc/hosts

# 2. Setup realm in Kerberos configuration vi /etc/krb5.conf

echo <<_EOF_ >> /etc/krb5.conf
includedir /etc/krb5.conf.d/

[logging]
    default = FILE:/var/log/krb5libs.log
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmind.log

[libdefaults]
    default_realm = MYREALM.EXAMPLE
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = yes
    default_tgs_enctypes = aes128-cts des3-hmac-sha1 des-cbc-crc des-cbc-md5
    default_tkt_enctypes = aes128-cts des3-hmac-sha1 des-cbc-crc des-cbc-md5
    permitted_enctypes = aes128-cts des3-hmac-sha1 des-cbc-crc des-cbc-md5

[realms]
    MYREALM.EXAMPLE = {
        kdc = myrealm.example
        admin_server = myrealm.example
    }

[domain_realm]
    .myrealm.example = MYREALM.EXAMPLE
    myrealm.example = MYREALM.EXAMPLE
_EOF_
# 3. Create KDC database

kdb5_util create -s

#4.  Add administrator to KDC database

kadmin.local -q "addprinc postgres/admin"

# 5. Create KDC deamon
      krb5kdc

# Database role in KDC database
kadmin.local -q "addprinc postgres/myrealm.example@MYREALM.EXAMPLE"

# Three parts of the principal “postgres/myrealm.example@MYREALM.EXAMPLE“
#            a. postgres - User needed by Postgresql server while connecting
#            b. myrealm.example - IP mapping to the KDC server
#            c. MYREALM.EXAMPLE - name of the realm as set in Kerberos configuration

# 2. Create keytab file

kadmin.local -q "xst -k myrealm.example.keytab postgres/myrealm.example@MYREALM.EXAMPLE"

# 3.  Set the ownership & permission for keytab file
chown postgres:postgres myrealm.example.keytab
chmod 400 myrealm.example.keytab

# Kerberos client-side setup(can be done using non-root user, I’m using Postgres user)
# 2. Remove existing ticket/token entries
su - postgres -c "kdestroy"

# 3. Request a ticket/token to KDC server
su - postgres -c "kinit -k -t myrealm.example.keytab  postgres/myrealm.example@MYREALM.EXAMPLE"

# 5. For verification, Display content of the ticket
su - postgres "klist"

#  Ticket cache: FILE:/tmp/krb5cc_1000
#  Default principal: postgres/myrealm.example@MYREALM.EXAMPLE
#  Valid starting     Expires            Service principal 08/21/15 18:10:08  08/22/15 18:10:08     krbtgt/MYREALM.EXAMPLE@MYREALM.EXAMPLE


# Setup database connection
# Create role in postgresql
psql -c 'CREATE ROLE "postgres/myrealm.example@MYREALM.EXAMPLE" SUPERUSER LOGIN'

# 2. Update postgresql.conf
krb_server_keyfile = '/home/postgres/myrealm.example.keytab'

# 3. Add host entry in pg_hba.conf

echo <<_EOF_ >> ${PGDATA}/pg_hba.conf
host all all 0.0.0.0/0 gss include_realm=1 krb_realm=MYREALM.EXAMPLE
_EOF_

# 4. Reload server parameter
psql -c "SELECT pg_reload_conf()"

# 5. Try to connect using GSSAPI/Kerberos
psql -U "postgres/myrealm.example@MYREALM.EXAMPLE" -h myrealm.example postgres
