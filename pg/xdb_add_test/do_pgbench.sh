#!/bin/bash

for ((i=0;i<100;i++))
do
  psql -U postgres postgres -c "create table archive_for_tokens${i} ( id serial primary key,
tag varchar(255),
app_key varchar(255),
app_name varchar(255),
id_arc integer,
type_arc varchar(255),
token_arc varchar(255),
secret_arc varchar(255),
callback_url_arc varchar(255),
verifier_arc varchar(255),
old_scope_arc varchar(255),
authorized_at_arc timestamp,
invalidated_at_arc timestamp,
expires_at_arc timestamp,
created_at_arc timestamp,
updated_at_arc timestamp,
kms_synced_arc boolean,
token_type_arc varchar(255),
refresh_token_arc varchar(255),
user_agent_arc varchar(255),
provider_clientapp_id_arc integer,
pending_arc boolean,
grant_type_parameter_arc varchar(255),
sync_riak_arc boolean,
consent_id_arc integer,
authentication_type_arc varchar(255),
created_at timestamp not null default now(),
updated_at timestamp not null default now()); "
done

for ((i=1;i<95;i++))
do
  j=$(( i * 10 ))
  pgbench -c ${j} -j 2 -r -T 600 -Cld -U postgres postgres &
  sleep 300
  java -jar /usr/ppas-xdb-5.1/bin/edb-repcli.jar -addtablesintopub xdbtest -repsvrfile /usr/ppas-xdb-5.1/etc/xdb_repsvrfile.conf -tables public.archive_for_tokens${i} -repgrouptype M
  sleep 300
done