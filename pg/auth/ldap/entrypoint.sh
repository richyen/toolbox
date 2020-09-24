#!/bin/bash

# Use [LDAP Cert setup guide](https://www.digitalocean.com/community/tutorials/how-to-encrypt-openldap-connections-using-starttls) as reference if necessary
yum -y install openldap-clients
echo 'TLS_CACERT /etc/openldap/ca_certs.pem' >> /etc/openldap/ldap.conf
cp /docker/certs/ca_server.pem /etc/openldap/ca_certs.pem
sed -i "s/host   all.*/host   all         all      0.0.0.0\/0  ldap ldapserver=ldap-service ldaptls=1 ldapport=389 ldapbasedn=\"dc=example,dc=org\" ldapbinddn=\"cn=admin,dc=example,dc=org\" ldapsearchattribute=uid ldapbindpasswd=admin/" $PGDATA/pg_hba.conf
su - enterprisedb -c "pg_ctl start"

# If having trouble auto-loading bootstrap.ldif via docker-compose.yml, use these 2 steps below
# cp /docker/ldif/bootstrap.ldif /tmp/bootstrap.ldif
# ldapmodify -x -H "ldap://ldap-service" -D "cn=admin,dc=example,dc=org" -w admin -f /tmp/bootstrap.ldif

# Test
while :; do
  echo "waiting for ldap-service to start"
  LDAPTEST=`ldapsearch -H "ldap://ldap-service" -D "cn=admin,dc=example,dc=org" -b "cn=enterprisedb,dc=example,dc=org" -Z -LLL -w admin cn`
  if [[ $? -eq 0 ]]; then
    break
  fi
done

# Test PG
echo "This should fail"
PGPASSWORD="foobar" psql -h 127.0.0.1 -c "select 'error not achieved'"

echo "This should succeed"
PGPASSWORD="abc123" psql -h 127.0.0.1 -c "select 'success'"

# Keep the container running
tail -f /dev/null
