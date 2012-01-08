#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST TERRACOTTAID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a TERRACOTTAID"; exit; fi

HOST=$1
TERRACOTTAID=$2

./log-status.sh "Starting Terracotta$TERRACOTTAID on $HOST"



#Send the latest config file
CONFTOUSE=$CONFDIR/terracotta/default.tc-config.xml
if [ -e $CONFDIR/terracotta/terracottaid$TERRACOTTAID.tc-config.xml ]; then
	./log.sh "$CONFDIR/terracotta/terracottaid$TERRACOTTAID.tc-config.xml exists"
    CONFTOUSE=$CONFDIR/terracotta/terracottaid$TERRACOTTAID.tc-config.xml
else
	./log.sh "$CONFDIR/terracotta/terracottaid$TERRACOTTAID.tc-config.xml not found, using default"
fi
#Move conftouse to a tmp file in data/
TMPCONF=data/terracottaid$TERRACOTTAID.tc-config.xml
rm -f $TMPCONF
cp $CONFTOUSE $TMPCONF

#Read Terracottas
exec 3<> $TERRACOTTASFILE; while read interracottas <&3; do {
	if [ $(echo "$interracottas" | cut -c1) != "#" ]; then
		TERRACOTTAID=$(echo "$interracottas" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$interracottas" | cut -d ":" -f2)
        #Read AMAZONIIDSFILE
        exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
            if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
                if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
                    AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                    TERRACOTTAINTERNALHOST=$(echo "$amazoniidsline" | cut -d ":" -f4)

                    #Now I have TERRACOTTAINTERNALHOST and TERRACOTTAID
                    sed -i "s/\[TERRACOTTAID.$TERRACOTTAID.INTERNALHOSTNAME\]/$TERRACOTTAINTERNALHOST/g" $TMPCONF

                fi
            fi
        }; done; exec 4>&-
	fi
}; done; exec 3>&-

#Send tc-config.cml to remote
ssh -t -t $HOST "mkdir -p terracotta-3.4.0_1"
scp $TMPCONF ec2-user@$HOST:tc-config.xml
ssh -t -t $HOST "cp tc-config.xml terracotta-3.4.0_1/tc-config.xml"
ssh -t -t $HOST "sudo chmod 755 terracotta-3.4.0_1/tc-config.xml"
ssh -t -t $HOST "rm tc-config.xml"

#Send the latest startup script
STARTUPSCRIPTTOUSE=$CONFDIR/terracotta/default.start-tc-server.sh
if [ -e $CONFDIR/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh ]; then
	./log.sh "$CONFDIR/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh exists"
    STARTUPSCRIPTTOUSE=$CONFDIR/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh
else
	./log.sh "$CONFDIR/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh not found, using default"
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
