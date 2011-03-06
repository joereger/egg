#!/bin/bash

export DONTREDITSTDOUTTOLOGFILE=1
source common.sh



hinit() {
    rm -f /tmp/hashmap.$1
}

hput() {
    echo "$2 $3" >> /tmp/hashmap.$1
}

hget() {
    grep "^$2 " /tmp/hashmap.$1 | awk '{ print $2 };'
}

hinit rows
hinit cols

#Clear the screen
tput clear



ROWS=0
exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
    if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
        TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
        LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
        APPNAME=$(echo "$intomcatline" | cut -d ":" -f3)
        APPDIR=$APPNAME$TOMCATID
        ROWS=$(( $ROWS + 1 ))
        tput cup $ROWS 1
        tput el
        echo "$APPDIR"
        KEY="$APPDIR"
        hput rows $KEY $ROWS
        hput cols $KEY 20
    fi
}; done; exec 3>&-

exec 3<> $INSTANCESFILE; while read ininstancesline <&3; do {
    if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
        LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
		AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
		ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
		EBSVOLUME=$(echo "$ininstancesline" | cut -d ":" -f6)
		EBSDEVICENAME=$(echo "$ininstancesline" | cut -d ":" -f7)
		exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
			if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
				LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
				if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
					AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
					HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
				fi
			fi
		}; done; exec 4>&-
        ROWS=$(( $ROWS + 1 ))
        tput cup $ROWS 1
        tput el
        echo "Instance$LOGICALINSTANCEID $AMAZONINSTANCEID"
        KEY="Instance$LOGICALINSTANCEID"
        hput rows $KEY $ROWS
        hput cols $KEY 20
    fi
}; done; exec 3>&-

exec 3<> $TERRACOTTASFILE; while read interracottas <&3; do {
	if [ $(echo "$interracottas" | cut -c1) != "#" ]; then
		TERRACOTTAID=$(echo "$interracottas" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$interracottas" | cut -d ":" -f2)
		ROWS=$(( $ROWS + 1 ))
        tput cup $ROWS 1
        tput el
        echo "Terracotta$TERRACOTTAID"
        KEY="Terracotta$TERRACOTTAID"
        hput rows $KEY $ROWS
        hput cols $KEY 20
	fi
}; done; exec 3>&-

exec 3<> $MYSQLSFILE; while read inmysqls <&3; do {
	if [ $(echo "$inmysqls" | cut -c1) != "#" ]; then
		MYSQLID=$(echo "$inmysqls" | cut -d ":" -f1)
		ROWS=$(( $ROWS + 1 ))
        tput cup $ROWS 1
        tput el
        echo "MySQL$MYSQLID"
        KEY="MySQL$MYSQLID"
        hput rows $KEY $ROWS
        hput cols $KEY 20
	fi
}; done; exec 3>&-



#This is the loop that updates the screen
export done="false"
while [ $done == "false" ]
do
    exec 3<> $PULSEFILE; while read pulseline <&3; do {
        if [ $(echo "$pulseline" | cut -c1) != "#" ]; then
            KEY=$(echo "$pulseline" | cut -d ":" -f1)
            VALUE=$(echo "$pulseline" | cut -d ":" -f2)
            ROW=`hget rows "$KEY"`
            COL=`hget cols "$KEY"`
            tput cup $ROW $COL
            if [ "$VALUE" == "OK" ]; then
                echo -e ${cf_green}$VALUE${c_reset}
            else
                echo -e ${cf_cyan}$VALUE${c_reset}
            fi
        fi
    }; done; exec 3>&-

    sleep 2
done









