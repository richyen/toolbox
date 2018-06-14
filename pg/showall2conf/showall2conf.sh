#!/bin/bash

# Simple script that takes a SHOW ALL output
# and converts it into a working postgresql.conf 
# file, used for assisting others by deploying
# an identical environment

FILE=${1}
DL='|'

SORTED=`cat ${FILE} | grep "${DL}" | cut -f 1-2 -d "${DL}" | awk '{ printf("%s = %s\n", $1, $3) }' | grep -v "name = setting"`; # > /tmp/sa2c.1.txt

# Ignore these params, as they don't belong in postgresql.conf, but show up in SHOW ALL anyways
# select name from pg_settings where source = 'override' or context = 'internal';
IGNORE_SETTINGS="block_size config_file custom_variable_classes default_transaction_isolation integer_datetimes lc_collate lc_ctype max_function_args max_identifier_length max_index_keys segment_size server_encoding server_version server_version_num transaction_isolation wal_block_size wal_segment_size data_checksums debug_assertions application_name config_file data_checksums data_directory hba_file icu_short_form ident_file lc_collate lc_ctype server_encoding transaction_deferrable transaction_isolation transaction_read_only wal_buffers"

for ignore in ${IGNORE_SETTINGS}; do SORTED=`echo "${SORTED}" | grep -v "^${ignore}\b"`; done

# Quote params that expect strings or otherwise need to be quoted
# select name from pg_settings where vartype in ('enum','string') and source <> 'override' and context <> 'internal';
QUOTE_SETTINGS="application_name archive_command archive_mode backslash_quote bonjour_name bytea_output client_encoding client_min_messages cluster_name constraint_exclusion custom_variable_classes DateStyle db_dialect default_tablespace default_text_search_config default_transaction_isolation dynamic_library_path dynamic_shared_memory_type edb_audit edb_audit_connect edb_audit_directory edb_audit_disconnect edb_audit_filename edb_audit_rotation_day edb_audit_statement edb_audit_tag edb_dynatune_profile edb_icache_servers edb_resource_group event_source external_pid_file huge_pages IntervalStyle krb_server_keyfile lc_messages lc_monetary lc_numeric lc_time listen_addresses local_preload_libraries log_destination log_directory log_error_verbosity log_filename log_line_prefix log_min_error_statement log_min_messages log_statement log_timezone odbc_lib_path optimizer_mode oracle_home qreplace_function search_path session_preload_libraries session_replication_role shared_preload_libraries ssl_ca_file ssl_cert_file ssl_ciphers ssl_crl_file ssl_ecdh_curve ssl_key_file stats_temp_directory synchronous_commit synchronous_standby_names syslog_facility syslog_ident temp_tablespaces TimeZone timezone_abbreviations trace_recovery_messages track_functions unix_socket_directories unix_socket_group wal_level wal_sync_method xmlbinary xmloption"

for quote in ${QUOTE_SETTINGS}; do SORTED=`echo "${SORTED}" | sed -E "s/${quote} = (.*)/${quote} = '\1'/"`; done

echo "${SORTED}"
