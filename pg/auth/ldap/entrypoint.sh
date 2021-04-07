#!/bin/bash

# Make sure PGDG is up-to-date (or else the subsequent `yum install` will complain)
yum install -y -q https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Use [LDAP Cert setup guide](https://www.digitalocean.com/community/tutorials/how-to-encrypt-openldap-connections-using-starttls) as reference if necessary
yum -y install openldap-clients
CA_CERT_FILE=/docker/certs/ca_server.pem
echo "TLS_CACERT ${CA_CERT_FILE}" >> /etc/openldap/ldap.conf

SIMPLEBIND_MODE=1
if [[ $SIMPLEBIND_MODE -eq 1 ]]; then
  sed -i "s/host   all.*/host   all         all      0.0.0.0\/0  ldap ldapserver=ldap-service ldaptls=1 ldapprefix=\"cn=\" ldapsuffix=\", dc=example, dc=org\" ldapport=389/" $PGDATA/pg_hba.conf
else
  sed -i "s/host   all.*/host   all         all      0.0.0.0\/0  ldap ldapurl=\"ldap:\/\/ldap-service\/dc=example,dc=org?uid?sub\" ldaptls=1 ldapbinddn=\"cn=admin,dc=example,dc=org\" ldapbindpasswd=admin/" $PGDATA/pg_hba.conf
fi

su - postgres -c "pg_ctl start"

# If having trouble auto-loading bootstrap.ldif via docker-compose.yml, use these 2 steps below
# cp /docker/ldif/bootstrap.ldif /tmp/bootstrap.ldif
# ldapmodify -x -H "ldap://ldap-service" -D "cn=admin,dc=example,dc=org" -w admin -f /tmp/bootstrap.ldif

# Test
while :; do
  echo "waiting for ldap-service to start"
  LDAPTEST=`ldapsearch -H "ldap://ldap-service" -D "cn=admin,dc=example,dc=org" -b "cn=postgres,dc=example,dc=org" -ZZ -LLL -w admin cn`
  RETVAL=$?
  if [[ $RETVAL -eq 0 ]]; then
    break
  fi
  sleep 1
done

# Test PG
echo "This should fail"
PGPASSWORD="foobar" psql -h 127.0.0.1 -c "select 'error not achieved'"

echo "This should succeed"
PGPASSWORD="abc123" psql -h 127.0.0.1 -c "select 'success'"

# Keep the container running
tail -f /dev/null
