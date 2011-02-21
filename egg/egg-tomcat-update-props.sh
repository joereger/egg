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

TOMCATSFILE=conf/tomcats.conf
MYSQLSFILE=conf/mysqls.conf
INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf
TERRACOTTASFILE=conf/terracottas.conf


if [ ! -f "$TOMCATSFILE" ]; then
  echo "Sorry, $TOMCATSFILE does not exist."
  exit 1
fi

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi


if [ ! -f "$MYSQLSFILE" ]; then
  echo "Sorry, $MYSQLSFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

if [ ! -f "$TERRACOTTASFILE" ]; then
  echo "Sorry, $TERRACOTTASFILE does not exist."
  exit 1
fi






#Read TOMCATSFILE
while read intomcatline;
do
	#Ignore lines that start with a comment hash mark
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
done < "$TOMCATSFILE"





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
while read inmysqlline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$inmysqlline" | cut -c1) != "#" ]; then

		MYSQLID=$(echo "$inmysqlline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$inmysqlline" | cut -d ":" -f2)

        #Read AMAZONIIDSFILE
        while read amazoniidsline;
        do
            #Ignore lines that start with a comment hash mark
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
        done < "$AMAZONIIDSFILE"
	fi
done < "$MYSQLSFILE"




#Replace [TERRACOTTAID.2.INTERNALHOSTNAME] with actual internal hostname
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
                    #Replace instances of [MYSQLID.$MYSQLID.INTERNALHOSTNAME] with $MYSQLINTERNALHOST
                    sed -i "s/\[TERRACOTTAID.$TERRACOTTAID.INTERNALHOSTNAME\]/$TERRACOTTAINTERNALHOST/g" data/$APP.tomcatid$TOMCATID.instance.props.tmp

                fi
            fi
        done < "$AMAZONIIDSFILE"
	fi
done < "$TERRACOTTASFILE"
