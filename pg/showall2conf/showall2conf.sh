#!/bin/bash

# Simple script that takes a SHOW ALL output
# and converts it into a working postgresql.conf 
# file, used for assisting others by deploying
# an identical environment

FILE=${1}
DL='|'

SORTED=`cat ${FILE} | grep "${DL}" | cut -f 1-2 -d "${DL}" | awk '{ printf("%s = %s\n", $1, $3) }' | grep -v "name = setting"`; # > /tmp/sa2c.1.txt

# Ignore these params, as they don't belong in postgresql.conf, but show up in SHOW ALL anyways
IGNORE_SETTINGS="block_size config_file custom_variable_classes default_transaction_isolation integer_datetimes lc_collate lc_ctype max_function_args max_identifier_length max_index_keys segment_size server_encoding server_version server_version_num transaction_isolation wal_block_size wal_segment_size"

for ignore in ${IGNORE_SETTINGS}; do SORTED=`echo "${SORTED}" | grep -v "^${ignore}\b"`; done

# Quote params that expect strings or otherwise need to be quoted
QUOTE_SETTINGS="archive_command bonjour_name data_directory DateStyle default_tablespace default_text_search_config dynamic_library_path edb_audit edb_audit_filename edb_audit_statement edb_icache_servers external_pid_file hba_file ident_file listen_addresses local_preload_libraries log_filename log_line_prefix odbc_lib_path oracle_home qreplace_function search_path shared_preload_libraries ssl_ca_file ssl_cert_file ssl_ciphers ssl_crl_file ssl_key_file synchronous_standby_names temp_tablespaces unix_socket_directory unix_socket_group"

for quote in ${QUOTE_SETTINGS}; do SORTED=`echo "${SORTED}" | sed -E "s/${quote} = (.*)/${quote} = '\1'/"`; done

echo "${SORTED}"
