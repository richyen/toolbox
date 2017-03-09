#!/bin/bash

#cd /usr/ppas/connectors/edboci/edb-oci/samples
make clean && make
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export EDB_HOME=/usr/ppas-9.5/
#export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/usr/lib64:/lib64:/usr/ppas/connectors/oci/lib
./OCIConnector
