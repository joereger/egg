#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST TERRACOTTAID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a TERRACOTTAID"; exit; fi

HOST=$1
TERRACOTTAID=$2

./log-status.sh "Starting Terracotta$TERRACOTTAID on $HOST"

AMAZONIIDSFILE=data/amazoniids.conf
TERRACOTTASFILE=conf/terracottas.conf


if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi


if [ ! -f "$TERRACOTTASFILE" ]; then
  echo "Sorry, $TERRACOTTASFILE does not exist."
  exit 1
fi


#Send the latest config file
CONFTOUSE=conf/terracotta/default.tc-config.xml
if [ -e conf/terracotta/terracottaid$TERRACOTTAID.tc-config.xml ]; then
	./log.sh "conf/terracotta/terracottaid$TERRACOTTAID.tc-config.xml exists"
    CONFTOUSE=conf/terracotta/terracottaid$TERRACOTTAID.tc-config.xml
else
	./log.sh "conf/terracotta/terracottaid$TERRACOTTAID.tc-config.xml not found, using default"
fi
#Move conftouse to a tmp file in data/
TMPCONF=data/terracottaid$TERRACOTTAID.tc-config.xml
rm -f $TMPCONF
cp $CONFTOUSE $TMPCONF

#Read Terracottas
while read interracottas;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$interracottas" | cut -c1) != "#" ]; then
		TERRACOTTAID=$(echo "$interracottas" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$interracottas" | cut -d ":" -f2)
        #Read AMAZONIIDSFILE
        while read amazoniidsline;
        do
            #Ignore lines that start with a comment hash mark
            if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
                if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
                    AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                    TERRACOTTAINTERNALHOST=$(echo "$amazoniidsline" | cut -d ":" -f4)

                    #Now I have TERRACOTTAINTERNALHOST and TERRACOTTAID
                    sed -i "s/\[TERRACOTTAID.$TERRACOTTAID.INTERNALHOSTNAME\]/$TERRACOTTAINTERNALHOST/g" $TMPCONF

                fi
            fi
        done < "$AMAZONIIDSFILE"
	fi
done < "$TERRACOTTASFILE"

#Send tc-config.cml to remote
ssh -t -t $HOST "mkdir -p terracotta-3.4.0_1"
scp $TMPCONF ec2-user@$HOST:tc-config.xml
ssh -t -t $HOST "cp tc-config.xml terracotta-3.4.0_1/tc-config.xml"
ssh -t -t $HOST "sudo chmod 755 terracotta-3.4.0_1/tc-config.xml"
ssh -t -t $HOST "rm tc-config.xml"

#Send the latest startup script
STARTUPSCRIPTTOUSE=conf/terracotta/default.start-tc-server.sh
if [ -e conf/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh ]; then
	./log.sh "conf/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh exists"
    STARTUPSCRIPTTOUSE=conf/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh
else
	./log.sh "conf/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh not found, using default"
fi
ssh -t -t $HOST "mkdir -p terracotta-3.4.0_1/bin"
scp $STARTUPSCRIPTTOUSE ec2-user@$HOST:start-tc-server.sh
ssh -t -t $HOST "cp start-tc-server.sh terracotta-3.4.0_1/bin/start-tc-server.sh"
ssh -t -t $HOST "sudo chmod 755 terracotta-3.4.0_1/bin/start-tc-server.sh"
ssh -t -t $HOST "rm start-tc-server.sh"

#Get on with the business of actually starting the server
ssh -t -t $HOST "mkdir terracotta"
ssh -t -t $HOST "touch terracotta/backgroundprocess.log"
ssh $HOST "export JAVA_HOME=/usr/lib/jvm/jre; nohup terracotta-3.4.0_1/bin/start-tc-server.sh -f /home/ec2-user/terracotta-3.4.0_1/tc-config.xml > terracotta/backgroundprocess.log 2>&1 & "
./log-status-green.sh "Terracotta started on $HOST"
