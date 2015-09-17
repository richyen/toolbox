!$/bin/bash

SLONY_LOG=''
SLONY_SCHEMA=''
NUM_TABLES=`psql -Atc "SELECT count(*) FROM _${SLONY_SCHEMA}.sl_table" -U postgres`
CURRENT_TABLE=`psql -Atc "select query from pg_stat_Activity where query like '%Table%Copy%'" -U postgres | sed -e "s:.*Copy(\(.*\)).*:\1:"`

if [[ "x${CURRENT_TABLE}" == "x" ]]
then
    CURRENT_TABLE=`cat ${SLONY_LOG} | grep ".*Table.*Copy" | sed -e "s:.*Copy(\(.*\)).*:\1:"`
fi

perl -e "printf(\"\%0.3f\n\",(${CURRRENT_TABLE}/$(NUM_TABLES})*100.0)"
