#!/bin/bash

set -x

# This script takes an image and attempts to
# create images of past versions of PostgreSQL
# by doing a `yum downgrade` and committing
# the downgraded version as an image

if [[ "${1}x" == 'x' ]]
then
  echo "Usage: ${0} <base_image_name>"
  exit 1
fi

BASE_IMG=${1}
TEMP_CON='dgrade'
REPO_NAME=`echo -n ${BASE_IMG} | sed -e 's/\(.*\):.*/\1/'`

DIST='postgresql'
if [[ ${BASE_IMG} =~ "pas" ]]
then
  DIST='edb-as'
fi

# Create base image
docker rm -f ${TEMP_CON}
docker run -itd --privileged --name=${TEMP_CON} ${BASE_IMG} bash

# Get Postgres version in container
CURR_VER=`docker exec -it ${TEMP_CON} psql --version | awk '{ print \$3 }'| tr -d '\r'`

while :;
do
  # Downgrade
  docker exec -it ${TEMP_CON} yum -y downgrade ${DIST}*

  # Get downgraded version number
  DOWN_VER=`docker exec -it ${TEMP_CON} psql --version | awk '{ print \$3 }'| tr -d '\r'`

  if [[ "${DOWN_VER}" == "${CURR_VER}" ]]
  then
    # Could not downgrade anymore, so we're done
    break
  else
    if [[ `docker images | grep ${REPO_NAME} | grep -c ${DOWN_VER}` -eq 0 ]]
    then
      # This tag does not exist, so create it
      docker commit ${TEMP_CON} ${REPO_NAME}:${DOWN_VER}
    fi

    # Set $CURR_VER and move on
    CURR_VER=${DOWN_VER}
  fi

  # Keep trying to downgrade until we can't do it anymore
done

docker rm -f ${TEMP_CON}
