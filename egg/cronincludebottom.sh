#!/bin/bash



CRONLOCKSFILE=data/cron.locks

if [ ! -f "$CRONLOCKSFILE" ]; then
  echo "$CRONLOCKSFILE does not exist so creating it."
  echo "$CRONLOCKSFILE does not exist so creating it." >> $LOGFILEDEBUG
  cp data/cron.locks.sample $CRONLOCKSFILE
fi

#Delete any current line with this logicalinstanceid
sed -i "
/^${CRONNAME}:/ d\
" $CRONLOCKSFILE


#End time counter
CRONENDTIME=`date +%s`
CRONEXECUTIONTIMEINSECONDS=$((CRONENDTIME-CRONSTARTTIME))
./log.sh "Cron $CRONNAME execution time: $CRONEXECUTIONTIMEINSECONDS seconds"




