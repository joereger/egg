#!/bin/bash

source common.sh

if [ "$#" -eq "0" ]; then echo "!USAGE: HOST APP APPDIR TOMCATID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APP"; exit; fi
if [ "$3" == "" ]; then echo "Must provide an APPDIR"; exit; fi
if [ "$4" == "" ]; then echo "Must provide a TOMCATID"; exit; fi

HOST=$1
APP=$2
APPDIR=$3
TOMCATID=$4

#Read TOMCATSFILE
exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
	if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then

	    TOMCATID_TMP=$(echo "$intomcatline" | cut -d ":" -f1)

	    if [ "$TOMCATID_TMP" == "$TOMCATID" ]; then

            #TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
            LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
            APPNAME=$(echo "$intomcatline" | cut -d ":" -f3)
            MEMMIN=$(echo "$intomcatline" | cut -d ":" -f4)
            MEMMAX=$(echo "$intomcatline" | cut -d ":" -f5)
            MAXTHREADS=$(echo "$intomcatline" | cut -d ":" -f6)
            JVMROUTE=$APPNAME$TOMCATID
            HTTPPORT=$((8100+$TOMCATID))

		fi

	fi
}; done; exec 3>&-





#Delete combined.props, in case it exists and then create the output/combined file
if [ -e data/$APP.tomcatid$TOMCATID.instance.props.tmp ]; then
	rm -f data/$APP.tomcatid$TOMCATID.instance.props.tmp
fi
mkdir -p "data"
touch "data/$APP.tomcatid$TOMCATID.instance.props.tmp"

#Determine which of system.props and/or instance.props exist and combine them into combined.props
if [ -e conf/apps/$APP/system.props ] && [ -e conf/apps/$APP/tomcatid$TOMCATID.instance.props ]; then
	echo "Both system.props and instance.props exist"
	cat conf/apps/$APP/system.props >> data/$APP.tomcatid$TOMCATID.instance.props.tmp
	echo -e "\n" >> data/$APP.tomcatid$TOMCATID.instance.props.tmp
	cat conf/apps/$APP/tomcatid$TOMCATID.instance.props >> data/$APP.tomcatid$TOMCATID.instance.props.tmp
elif [ -e conf/apps/$APP/system.props ]; then
	echo "Only system.props exists"
	cp conf/apps/$APP/system.props data/$APP.tomcatid$TOMCATID.instance.props.tmp
elif [ -e conf/apps/$APP/tomcatid$TOMCATID.instance.props ]; then
	echo "Only instance.props exists"
	cp conf/apps/$APP/tomcatid$TOMCATID.instance.props data/$APP.tomcatid$TOMCATID.instance.props.tmp
else
	echo "Neither instance.props nor system.props exist"
fi



#Insert Tomcatid
sed -i "s/\[TOMCATID\]/$TOMCATID/g" data/$APP.tomcatid$TOMCATID.instance.props.tmp


#Replace [MYSQLID.2.INTERNALHOSTNAME] with actual internal hostname
#Read Mysqls
exec 3<> $MYSQLSFILE; while read inmysqlsline <&3; do {
	if [ $(echo "$inmysqlsline" | cut -c1) != "#" ]; then

		MYSQLID=$(echo "$inmysqlsline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$inmysqlsline" | cut -d ":" -f2)

        #Read AMAZONIIDSFILE
        exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
            if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
                if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
                    AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                    MYSQLINTERNALHOST=$(echo "$amazoniidsline" | cut -d ":" -f4)

                    #Now I have MYSQLINTERNALHOST and MYSQLID
                    #Replace instances of [MYSQLID.$MYSQLID.INTERNALHOSTNAME] with $MYSQLINTERNALHOST
                    sed -i "s/\[MYSQLID.$MYSQLID.INTERNALHOSTNAME\]/$MYSQLINTERNALHOST/g" data/$APP.tomcatid$TOMCATID.instance.props.tmp

                fi
            fi
        }; done; exec 4>&-
	fi
}; done; exec 3>&-




#Replace [TERRACOTTAID.2.INTERNALHOSTNAME] with actual internal hostname
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
                    #Replace instances of [MYSQLID.$MYSQLID.INTERNALHOSTNAME] with $MYSQLINTERNALHOST
                    sed -i "s/\[TERRACOTTAID.$TERRACOTTAID.INTERNALHOSTNAME\]/$TERRACOTTAINTERNALHOST/g" data/$APP.tomcatid$TOMCATID.instance.props.tmp

                fi
            fi
        }; done; exec 4>&-
	fi
}; done; exec 3>&-


#Replace [JGROUPS.TCP.PORT] with the port for *this* instance
#Note that this must line up with the port number for *this* instance calculated below for HOSTLIST
JGROUPSTCPPORTTHIS=$((9000+($TOMCATID*10)))
echo "JGROUPSTCPPORTTHIS=$JGROUPSTCPPORTTHIS"
#Replace instances of [JGROUPS.TCP.PORT] with $JGROUPSTCPPORTTHIS
sed -i "s/\[JGROUPS.TCP.PORT\]/$JGROUPSTCPPORTTHIS/g" data/$APP.tomcatid$TOMCATID.instance.props.tmp


#Replace [JGROUPS.TCPPING.INITIALHOSTS] with list of hosts in this cluster
#Iterate tocmats to find hosts
HOSTLIST=""
JGROUPSTCPPORT=9000
exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
	if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then

		TOMCATID_A=$(echo "$intomcatline" | cut -d ":" -f1)
		LOGICALINSTANCEID_A=$(echo "$intomcatline" | cut -d ":" -f2)
		APPNAME_A=$(echo "$intomcatline" | cut -d ":" -f3)
		HTTPPORT_A=$((8100+$TOMCATID_A))

		if [ "$APPNAME_A" == "$APP" ]; then

			#Read AMAZONIIDSFILE
            AMAZONINSTANCEID=""
            HOST=""

            JGROUPSTCPPORT=$((9000+($TOMCATID_A*10)))
            echo "JGROUPSTCPPORT=$JGROUPSTCPPORT"

            exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
                if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                    LOGICALINSTANCEID_C=$(echo "$amazoniidsline" | cut -d ":" -f1)
                    if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID_C" ]; then
                        AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                        HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
                        INTERNALHOSTNAME=$(echo "$amazoniidsline" | cut -d ":" -f4)
                        echo "HOSTLIST=${HOSTLIST}"
                        if [ "$HOSTLIST" == "" ]; then
                            HOSTLIST="${HOST}[${JGROUPSTCPPORT}]"
                        else
                            HOSTLIST="${HOSTLIST},${HOST}[${JGROUPSTCPPORT}]"
                        fi

                    fi
                fi
            }; done; exec 4>&-

		fi
	fi
}; done; exec 3>&-
echo "Final HOSTLIST=${HOSTLIST}"
#Now I have list of hosts
#Replace instances of [JGROUPS.TCPPING.INITIALHOSTS] with $HOSTLIST
sed -i "s/\[JGROUPS.TCPPING.INITIALHOSTS\]/$HOSTLIST/g" data/$APP.tomcatid$TOMCATID.instance.props.tmp
