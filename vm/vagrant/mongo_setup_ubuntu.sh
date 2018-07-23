#!/bin/bash

set -e
set -x

# Install MongoDB 3.6 for Ubuntu
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 58712A2291FA4AD5
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list
apt-get update
apt-get -y install mongodb-org

# Create service script
cat << EOF > /lib/systemd/system/mongod.service
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target
Documentation=https://docs.mongodb.org/manual

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --bind_ip_all --config /etc/mongod.conf
PIDFile=/var/run/mongodb/mongod.pid
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false

# Recommended limits for for mongod as specified in
# http://docs.mongodb.org/manual/reference/ulimit/#recommended-settings

[Install]
WantedBy=multi-user.target
EOF

# Start MongoDB
systemctl daemon-reload
systemctl start mongod

# Set admin password
sleep 5
mongo 127.0.0.1:27017/admin --eval 'db.createUser({user:"admin", pwd:"password", roles:[{role:"root", db:"admin"}]})'

# Turn on authentication
systemctl stop mongod
cat << EOF >> /etc/mongod.conf
security:
  authorization: enabled
EOF

sed -i "s/--bind_ip_all/--auth --bind_ip_all/" /lib/systemd/system/mongod.service
systemctl start mongod

# Test
sleep 5
mongo --host 127.0.0.1 --port 27017 --username admin --authenticationDatabase admin --password password --eval "db.version()"
