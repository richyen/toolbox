#!/bin/bash

if [[ "${1}x" == 'x' ]]
then
  echo "No repository URL provided. Please provide a repository URL as argument"
  echo "Usage: ${0} <repository_url:port>"
  exit 1
fi

for i in 9.6 10 11 12 13
do
  # Build new images
  R=${1}
  V=${i/./}
  V7=${R}/centos7/epas${V}
  EDBR="docker-reg.ma.us.enterprisedb.com:5000"
  EV7=${EDBR}/centos7/epas${V}
  docker build --build-arg RPM_URL="${RPM_URL}" --build-arg YUMUSERNAME=${YUMUSERNAME} --build-arg YUMPASSWORD=${YUMPASSWORD} --build-arg PGMAJOR=${i} -t ${V7}:latest -f Dockerfile.template . &

  # Set tags
  VN=`docker run -it --rm ${R}/centos7/epas${V}:latest psql --version | awk '{ print \$3 }' | tr -d '\r'`
  docker tag ${V7}:latest ${V7}:${VN}
  docker tag ${V7}:latest ${EV7}:${VN}
  docker tag ${V7}:latest ${EV7}:latest

  # Push images to registry
  docker push ${V7}:latest
  docker push ${V7}:${VN}
  docker push ${EV7}:latest
  docker push ${EV7}:${VN}
done
