#!/bin/bash

### A simple tool to list available images in a docker registry

REGISTRY_URL=${1}
REGISTRY_PORT=${2}

### Sample output: {"repositories":["efm","epas10","epas96","pemagent","pemserver","ppas91","ppas92","ppas93","ppas94","ppas95","xdb"]}
REPOS_RAW=`curl --silent -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X GET https://${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}@${REGISTRY_URL}:${REGISTRY_PORT}/v2/_catalog`
REPOS=`echo ${REPOS_RAW} | sed -e "s/.*\[//" -e "s/].*//" -e 's/"//g' -e "s/,/ /g"`

echo "Available images in ${REGISTRY_URL}:${REGISTRY_PORT} are:"
for i in ${REPOS}
do
  echo "REPO ${i} -- "
  TAGS_RAW=`curl --silent -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X GET https://${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}@${REGISTRY_URL}:${REGISTRY_PORT}/v2/${i}/tags/list`
  TAGS=`echo ${TAGS_RAW} | sed -e "s/.*\[//" -e "s/].*//" -e 's/"//g' -e "s/,/ /g"`
  for j in ${TAGS}
  do
    echo "  ${i}:${j}"
  done
done

echo "You may pull images by first logging in with \`docker login ${REGISTRY_URL}:${REGISTRY_PORT}\`"
echo "Then pull your desired image with \`docker pull ${REGISTRY_URL}:${REGISTRY_PORT}/<repo>:<version>\`"
