#!/bin/bash

gcc -g -Wall -I/u01/app/oracle/product/11.2.0/xe/rdbms/public oci_dynamic_fetch.c -L/usr/edb/connectors/oci/lib -ledboci -o oci_dynamic_fetch
gcc -g -Wall -I/u01/app/oracle/product/11.2.0/xe/rdbms/public oci_fetch2.c -L/usr/edb/connectors/oci/lib -ledboci -o oci_fetch2
