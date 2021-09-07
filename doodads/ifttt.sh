#!/bin/sh
# Adapted from: https://gist.github.com/randName/cf2f924098af19e8d943ddcbca5a26a2

[ ! -f ~/.ifttt ] && echo "~/.ifttt not found" && exit 1

. ~/.ifttt

[ -z "$IFTTT_KEY" ] && echo "Please set your IFTTT key in ~/.ifttt.\nFormat:\n\nexport IFTTT_KEY=<your_key>" && exit 1

if [ -z "$EVENT" ]; then
    # If not defined in ~/.ifttt, then specify a default event name here
    EVENT="script_finished"
fi

# Run desired script
LOGFILE=/tmp/log.log
echo "foo" >> ${LOGFILE}

# Capture exit status
if [[ ${?} -eq 0 ]]; then
  STATUS="success"
else
  STATUS="failure"
fi

# Grab the last few lines of log
MESSAGE=$(tail -n 5 ${LOGFILE} | tr '\n' '|')

# Send it all to IFTTT
URL="https://maker.ifttt.com/trigger/$EVENT/json/with/key/$IFTTT_KEY"
DATA="{\"value1\":\"${STATUS}\",\"value2\":\"${MESSAGE}\",\"value3\":\"$@\"}"
RTN="$(curl -s -X POST -H "Content-Type: application/json" -d "$DATA" "$URL")"
