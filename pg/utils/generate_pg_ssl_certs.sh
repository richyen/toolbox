#!/bin/bash

CERT_COMMON_NAME="PG"
CERT_COUNTRY="US"
CERT_STATE="CA"
CERT_CITY="San Diego"
CERT_ORG_UNIT="Postgres"
CERT_EMAIL="richard.yen@edb.com"

# Setup
# Make sure sslutils are installed via yum
yum -y -q install sslutils_${PG_VERSION} postgresql${PG_VERSION}-contrib openssl openssl-devel

su - ${PGUSER} -c "pg_ctl start"
PG_VERSION=$( cat ${PGDATA}/PG_VERSION )
psql -Atqc "CREATE EXTENSION hstore;"
psql -Atqc "CREATE EXTENSION sslutils;"
cd ${PGDATA}

# Certificate Authority
psql -Atqc "SELECT public.openssl_rsa_generate_key(4096);" >  ${PGDATA}/ca_key.key
chown ${PGUSER}:${PGUSER} ${PGDATA}/ca_key.key
chmod 600 ${PGDATA}/ca_key.key

CA_KEY=$(cat ${PGDATA}/ca_key.key)

psql -Atqc "SELECT openssl_csr_to_crt(openssl_rsa_key_to_csr( '${CA_KEY}', '${CERT_COMMON_NAME}', '${CERT_COUNTRY}', '${CERT_STATE}', '${CERT_CITY}', '${CERT_ORG_UNIT}', '${CERT_EMAIL}' ), NULL, '${PGDATA}/ca_key.key');" > ${PGDATA}/ca_certificate.crt
chown ${PGUSER}:${PGUSER} ${PGDATA}/ca_certificate.crt
chmod 600 ${PGDATA}/ca_certificate.crt

# root
cp ${PGDATA}/ca_certificate.crt ${PGDATA}/root.crt
chown ${PGUSER}:${PGUSER} ${PGDATA}/root.crt
chmod 600 ${PGDATA}/root.crt

psql -Atqc "SELECT openssl_rsa_generate_crl('${PGDATA}/ca_certificate.crt', '${PGDATA}/ca_key.key');" > ${PGDATA}/root.crl
chown ${PGUSER}:${PGUSER} ${PGDATA}/root.crl
chmod 600 ${PGDATA}/root.crl

# server
psql -Atqc "SELECT public.openssl_rsa_generate_key(4096);" >> ${PGDATA}/server.key
chown ${PGUSER}:${PGUSER} ${PGDATA}/server.key
chmod 600 ${PGDATA}/server.key

SSL_KEY=$(cat ${PGDATA}/server.key)
psql -Atqc "SELECT openssl_csr_to_crt(openssl_rsa_key_to_csr( '${SSL_KEY}', '${CERT_COMMON_NAME}', '${CERT_COUNTRY}', '${CERT_STATE}', '${CERT_CITY}', '${CERT_ORG_UNIT}', '${CERT_EMAIL}' ), NULL, '${PGDATA}/ca_key.key');" > ${PGDATA}/server.crt
chown ${PGUSER}:${PGUSER} ${PGDATA}/server.crt
chmod 600 ${PGDATA}/server.crt

echo "ssl = on" >> ${PGDATA}/postgresql.conf
su - ${PGUSER} -c "pg_ctl restart"

# This can now be tested with psql or openssl
# Be sure pg_hba.conf has a hostssl entry
# openssl s_client -connect localhost:5432 -starttls postgres -tls1
