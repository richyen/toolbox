#!/bin/bash

YUMUSERNAME=""
YUMPASSWORD=""
U="ec2-user"
set -e
set -x
yum -y install git wget
git clone https://github.com/richyen/ppas_and_docker.git &
git clone https://github.com/richyen/toolbox.git &
yum -y update
tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
yum -y install docker-engine
service docker start
cd /home/${U}/ppas_and_docker && git checkout merge
docker build --build-arg YUMUSERNAME=${YUMUSERNAME} --build-arg YUMPASSWORD=${YUMPASSWORD} -t ppas95:latest /home/${U}/ppas_and_docker/epas/9.5
# do XDB 6 image first, and run in background, so by the time xdb_mmr_demo for XDB 5 is done, xdb_mmr_demo for XDB 6 can run
docker build --build-arg YUMUSERNAME=${YUMUSERNAME} --build-arg YUMPASSWORD=${YUMPASSWORD} -t xdb6:latest /home/${U}/ppas_and_docker/xdb/6.0 &
docker build --build-arg YUMUSERNAME=${YUMUSERNAME} --build-arg YUMPASSWORD=${YUMPASSWORD} -t xdb51:latest /home/${U}/ppas_and_docker/xdb/5.1
sed -i "s/Users.*Desktop/home\/${U}:\/Desktop/" /home/${U}/ppas_and_docker/xdb/xdb_mmr_demo.sh
sed -i "s/^num_nodes=4/num_nodes=8/" /home/${U}/ppas_and_docker/xdb/xdb_mmr_demo.sh
/home/${U}/ppas_and_docker/xdb/xdb_mmr_demo.sh 5
/home/${U}/ppas_and_docker/xdb/xdb_mmr_demo.sh 6
/home/${U}/toolbox/pg/xdb_connectivity_test/connectivity_demo.sh 5
/home/${U}/toolbox/pg/xdb_connectivity_test/connectivity_demo.sh 6
