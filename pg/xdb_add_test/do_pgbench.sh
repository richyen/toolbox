#!/bin/bash

pgbench -c 50 -j 50 -r -T 600 -h ${MDN_IP} -Cld edb