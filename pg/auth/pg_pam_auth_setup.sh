#!/bin/bash

# Basic test for PAM functionality

cat << _EOF_ > /mytest.sh
#!/bin/sh
read password
if [ "$PAM_USER" == "abc" ] && [ "$password" == "123" ] ; then
 exit 0
else
 exit 1
fi
_EOF_

chmod 755 /mytest.sh

yum -y install epel-release pam-devel.x86_64 pamtester

echo "auth required /lib64/security/pam_exec.so expose_authtok /mytest.sh" > /etc/pam.d/my-service
echo "account required pam_permit.so" >> /etc/pam.d/my-service

# At this point, you should be able to call `pamtester my-service abc authenticate`
# with the password "123" and get a success message

psql -c "CREATE USER abc WITH LOGIN"

# Alter `pg_hba.conf` with `pam pamservice=my-service` as the authetication method
# Reload the conf (`SELECT pg_reload_conf()`) and attempt to log in as the `abc` user
