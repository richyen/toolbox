!$/bin/bash

SLONY_SCHEMA=''
NUM_TABLES=`psql -Atc "SELECT count(*) FROM _${SLONY_SCHEMA}.sl_table" -U postgres`
CURRENT_TABLE=`psql -Atc "select query from pg_stat_Activity where query like '%Table%Copy%'" -U postgres | sed -e "s:.*Copy(\(.*\)).*:\1:"`

perl -e "printf(\"\%0.3f\n\",(${CURRRENT_TABLE}/$(NUM_TABLES})*100.0)"
