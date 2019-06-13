#!/bin/bash

# Assumes Postgres is installed and running

PGDATA="/var/lib/pgsql/11/data"
PGUSER="postgres"
PGDATABASE="postgres"
SERVICE="postgresql-11"

# Create server cert
openssl req -new -text -nodes -subj "/C=US/ST=Massachusetts/L=Bedford/O=EnterpriseDB/OU=XDB/emailAddress=support@enterprisedb.com/CN=${PGUSER}" -keyout ${PGDATA}/server.key -out ${PGDATA}/server.csr
openssl x509 -req -days 365 -in ${PGDATA}/server.csr -signkey ${PGDATA}/server.key -out ${PGDATA}/server.crt
cp ${PGDATA}/server.crt ${PGDATA}/root.crt
rm ${PGDATA}/server.csr
chown ${PGUSER} ${PGDATA}/root.crt ${PGDATA}/server.crt ${PGDATA}/server.key
chgrp ${PGUSER} ${PGDATA}/root.crt ${PGDATA}/server.crt ${PGDATA}/server.key
chmod 600 ${PGDATA}/root.crt ${PGDATA}/server.crt ${PGDATA}/server.key

# Turn on SSL for the server
echo "ssl = on"                     >> ${PGDATA}/postgresql.conf
echo "ssl_cert_file = 'server.crt'" >> ${PGDATA}/postgresql.conf
echo "ssl_key_file = 'server.key'"  >> ${PGDATA}/postgresql.conf
echo "ssl_ca_file = 'root.crt'"     >> ${PGDATA}/postgresql.conf

# Set up pg_hba.conf
echo "local   all all           trust"                          >  ${PGDATA}/pg_hba.conf
echo "hostssl all all 0.0.0.0/0 cert clientcert=1 map=sslusers" >> ${PGDATA}/pg_hba.conf

# Set up pg_ident mappings
echo "sslusers ${PGUSER} ${PGUSER}" >  ${PGDATA}/pg_ident.conf
echo "sslusers root      ${PGUSER}" >> ${PGDATA}/pg_ident.conf

# Restart server
service ${SERVICE} restart

# Attempt to log in unsuccessfully
psql -h 127.0.0.1 -c "SELECT 'this should have failed'" ${PGDATABASE} ${PGUSER}

# Create client cert
# Note that in the real world, a new cert may need to be generated.
# Basically, the common name (CN) in the cert needs to match the
# desired ${PGUSER}, and a corresponding OS->PG map needs to be
# included in pg_ident.conf
mkdir ~/.postgresql
cp ${PGDATA}/server.crt ~/.postgresql/postgresql.crt
cp ${PGDATA}/server.key ~/.postgresql/postgresql.key

# Attempt to log in successfully
psql -h 127.0.0.1 -c "SELECT 'success'" ${PGDATABASE} ${PGUSER}
