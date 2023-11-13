#!/bin/bash

os_list="rockylinux:8 rockylinux:9 almalinux:8 almalinux:9"
if [[ ${OS_ARCH} == "deb" ]]; then
  os_list="ubuntu:20.04 debian:10 ubuntu:18.04 debian:11 ubuntu:22.04"
fi
log="output.log"

for os in ${os_list}; do
  echo ${os}
  where_clause="version in ('8','9') and command_line ilike '%yum%' or command_line ilike '%dnf%'"
  if [[ ${OS_ARCH} == "deb" ]]; then
    where_clause="lower(name) || ':' || version = '${os}'"
  fi

  packages_list=`psql -h ${PGHOST} -U strapi prdata -Atc "SELECT distinct(name) FROM edb_repo.distributables WHERE operating_system_id = (SELECT id from edb_repo.operating_systems WHERE ${where_clause}) AND product_version_id IN (select id from edb_repo.product_versions WHERE effdt_start > now() - interval '1 month')"`

  for pkg in ${packages_list}; do
  echo ${pkg}
  echo "ATTEMPT - ${pkg} on ${os}" >> ${log}
  docker run -it --rm -v ./:/downloads_test -e OS_ARCH=${OS_ARCH} -e TOKEN_URL=${TOKEN_URL} ${os} /downloads_test/entrypoint.sh ${pkg}
  if [[ ${?} -eq 0 ]]; then
    echo "SUCCESS - ${pkg} on ${os}" >> ${log}
  else
    echo "FAILURE - ${pkg} on ${os}" >> ${log}
  fi
  done
done
