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

MYSQLSFILE=conf/mysqls.conf
INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf
TERRACOTTASFILE=conf/terracottas.conf

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


#Delete combined.props, in case it exists and then create the output/combined file
if [ -e conf/$APP/combined.props ]; then
	rm conf/$APP/combined.props
fi
mkdir -p "conf/$APP"
touch "conf/$APP/combined.props"

#Determine which of system.props and/or instance.props exist and combine them into combined.props
if [ -e conf/$APP/system.props ] && [ -e conf/$APP/instance.tomcatid$TOMCATID.props ]; then
	echo "Both system.props and instance.props exist"
	cat conf/$APP/system.props >> conf/$APP/combined.props
	echo -e "\n" >> conf/$APP/combined.props
	cat conf/$APP/instance.tomcatid$TOMCATID.props >> conf/$APP/combined.props
elif [ -e conf/$APP/system.props ]; then
	echo "Only system.props exists"
	cp conf/$APP/system.props conf/$APP/combined.props
elif [ -e conf/$APP/instance.tomcatid$TOMCATID.props ]; then
	echo "Only instance.props exists"
	cp conf/$APP/instance.tomcatid$TOMCATID.props conf/$APP/combined.props
else
	echo "Neither instance.props nor system.props exist"
fi

#Replace [MYSQLID.2.INTERNALHOSTNAME] with actual internal hostname
#Read Mysqls
while read interracottas;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$interracottas" | cut -c1) != "#" ]; then

		MYSQLID=$(echo "$interracottas" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$interracottas" | cut -d ":" -f2)

		#Read INSTANCESFILE
		while read ininstancesline;
		do
			#Ignore lines that start with a comment hash mark
			if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then

				LOGICALINSTANCEID_B=$(echo "$ininstancesline" | cut -d ":" -f1)

				if [ "$LOGICALINSTANCEID_B" == "$LOGICALINSTANCEID" ]; then

					#Read AMAZONIIDSFILE
					AMAZONINSTANCEID=""
					MYSQLINTERNALHOST=""
					while read amazoniidsline;
					do
						#Ignore lines that start with a comment hash mark
						if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
							LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
							if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
								AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
								MYSQLINTERNALHOST=$(echo "$amazoniidsline" | cut -d ":" -f4)
							fi
						fi
					done < "$AMAZONIIDSFILE"

					#Now I have MYSQLINTERNALHOST and MYSQLID
					#Replace instances of [MYSQLID.$MYSQLID.INTERNALHOSTNAME] with $MYSQLINTERNALHOST
                    sed -i "s/\[MYSQLID.$MYSQLID.INTERNALHOSTNAME\]/$MYSQLINTERNALHOST/g" conf/$APP/combined.props

				fi
			fi
		done < "$INSTANCESFILE"
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

		#Read INSTANCESFILE
		while read ininstancesline;
		do
			#Ignore lines that start with a comment hash mark
			if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then

				LOGICALINSTANCEID_B=$(echo "$ininstancesline" | cut -d ":" -f1)

				if [ "$LOGICALINSTANCEID_B" == "$LOGICALINSTANCEID" ]; then

					#Read AMAZONIIDSFILE
					AMAZONINSTANCEID=""
					TERRACOTTAINTERNALHOST=""
					while read amazoniidsline;
					do
						#Ignore lines that start with a comment hash mark
						if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
							LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
							if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
								AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
								TERRACOTTAINTERNALHOST=$(echo "$amazoniidsline" | cut -d ":" -f4)
							fi
						fi
					done < "$AMAZONIIDSFILE"

					#Now I have TERRACOTTAINTERNALHOST and TERRACOTTAID
					#Replace instances of [MYSQLID.$MYSQLID.INTERNALHOSTNAME] with $MYSQLINTERNALHOST
                    sed -i "s/\[TERRACOTTAID.$TERRACOTTAID.INTERNALHOSTNAME\]/$TERRACOTTAINTERNALHOST/g" conf/$APP/combined.props

				fi
			fi
		done < "$INSTANCESFILE"
	fi
done < "$TERRACOTTASFILE"







#Make sure /conf exists
ssh -t -t $HOST "mkdir -p egg/$APPDIR/tomcat/webapps/ROOT/conf"

#Copy combined.props to instance.props on remote Tomcat
scp conf/$APP/combined.props ec2-user@$HOST:~/egg/$APPDIR/tomcat/webapps/ROOT/conf/instance.props

#Delete combined.props
rm conf/$APP/combined.props
