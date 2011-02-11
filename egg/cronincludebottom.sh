#!/bin/bash



CRONLOCKSFILE=data/cron.locks

if [ ! -f "$CRONLOCKSFILE" ]; then
  echo "$CRONLOCKSFILE does not exist so creating it."
  echo "$CRONLOCKSFILE does not exist so creating it." >> /home/ec2-user/egg/logs/debug.log
  cp data/cron.locks.sample $CRONLOCKSFILE
fi

#Delete any current line with this logicalinstanceid
sed -i "
/^${CRONNAME}:/ d\
" $CRONLOCKSFILE

