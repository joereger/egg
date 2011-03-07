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


            #HTTP Check
            ./log.sh "Start HTTP Check $APPDIR"
            url="http://$HOST:$HTTPPORT/"
            retries=0
            timeout=120
            #status=`wget --tries 1 --timeout 120 $url 2>&1 | egrep "HTTP" | awk {'print $6'}`
            #$status=`wget --tries 1 --timeout 120 $url`

            #"HTTP request sent, awaiting response... 200 OK"

            mkdir -p logs/wget
            WGETSTARTTIME=$(date +%s.%N)
            export status=`wget --tries 1 --timeout 120 -O logs/wget/$APPNAME$TOMCATID.html $url 2>&1`
            WGETENDTIME=$(date +%s.%N)
            WGETEXECUTIONTIME=$(echo "$WGETENDTIME - $WGETSTARTTIME" | bc)
            STATUSSMALL=$(echo $status | cut -c97-175)
            #--2011-03-02 17:58:12-- http://10.254.98.230:8110/ Connecting to 10.254.98.230:8110... connected.
            CTIME=`TZ=EST date +"%b %d %r %N"`
            echo -e "[$CTIME] $WGETEXECUTIONTIME \t$APPDIR \t$STATUSSMALL" >> logs/wget.log
            ISOK=0
            if [[ $status == *"HTTP request sent, awaiting response... 200 OK"* ]]; then
                ISOK=1
            elif [[ $status == *"302 Moved Temp"* ]]; then
                ISOK=1
            fi

            if [ "$ISOK" == "1" ]; then
                ./log.sh "Tomcat $APPDIR wget success $WGETEXECUTIONTIME seconds, recording LASTGOOD"
                ./pulse-update.sh $APPDIR "OK, ${WGETEXECUTIONTIME}sec"
                #./pulse-update.sh "${$APPDIR}WGET" "$WGETEXECUTIONTIME"
                CURRENTTIME=`date +%s`
                #Delete any current line with this tomcatid
                sed -i "
                /^${TOMCATID}:/ d\
                " $CHECKTOMCATSFILE
                #Write a new record
                sed -i "
                /#BEGINDATA/ a\
                $TOMCATID:$CURRENTTIME
                " $CHECKTOMCATSFILE
            else
                #This big loop just done to collect better logging/emailing data (namely LASTGOODSECONDSAGO)
                exec 4<> $CHECKTOMCATSFILE; while read incheckline <&4; do {
                    if [ $(echo "$incheckline" | cut -c1) != "#" ]; then
                        TOMCATID_CHK=$(echo "$incheckline" | cut -d ":" -f1)
                        if [ "$TOMCATID_CHK" == "$TOMCATID" ]; then
                            LASTGOOD=$(echo "$incheckline" | cut -d ":" -f2)
                            CURRENTTIME=`date +%s`
                            LASTGOODSECONDSAGO=$((CURRENTTIME-LASTGOOD))
                        fi
                    fi
                }; done; exec 4>&-
                ./pulse-update.sh $APPDIR "Fail ${LASTGOODSECONDSAGO} sec"
                ./log-status-red.sh "Tomcat $APPDIR fails wget $WGETEXECUTIONTIME seconds, LASTGOODSECONDSAGO=$LASTGOODSECONDSAGO"
                ./mail.sh "Tomcat $APPDIR fails wget $WGETEXECUTIONTIME seconds, LASTGOODSECONDSAGO=$LASTGOODSECONDSAGO" "status=$status"
            fi






            #This is max time that tomcat can be down before restart
            MAXLASTGOOD=600
            #Figure out how long since last good
            #Read CHECKTOMCATSFILE
            foundtomcatidincheckfile=0
            exec 4<> $CHECKTOMCATSFILE; while read incheckline <&4; do {
                if [ $(echo "$incheckline" | cut -c1) != "#" ]; then

                    TOMCATID_CHK=$(echo "$incheckline" | cut -d ":" -f1)

                    if [ "$TOMCATID_CHK" == "$TOMCATID" ]; then
                        foundtomcatidincheckfile=1
                        LASTGOOD=$(echo "$incheckline" | cut -d ":" -f2)
                        CURRENTTIME=`date +%s`
                        LASTGOODSECONDSAGO=$((CURRENTTIME-LASTGOOD))
                        ./log.sh $APPDIR LASTGOODSECONDSAGO=$LASTGOODSECONDSAGO
                        if [ "${LASTGOODSECONDSAGO}" -gt "${MAXLASTGOOD}"  ]; then
                            ./pulse-update.sh $APPDIR "Restarting"
                            ./mail.sh "Tomcat $APPDIR down > $MAXLASTGOOD seconds, restarting" "LASTGOODSECONDSAGO=$LASTGOODSECONDSAGO"
                            ./log-status-red.sh "Tomcat $APPDIR down > $MAXLASTGOOD seconds, restarting"
                            ./egg-tomcat-stop.sh $HOST $APPDIR
                            ./egg-tomcat-start.sh $TOMCATID $HOST $APPDIR $MEMMIN $MEMMAX
                            ./pulse-update.sh $APPDIR "Wait Tomcat Come Up"
                            ./log-status.sh "Sleeping 30 sec for Tomcat $APPDIR to come up"
                            sleep 30
                            #Delete any current line with this tomcatid
                            sed -i "
                            /^${TOMCATID}:/ d\
                            " $CHECKTOMCATSFILE
                        fi
                    fi

                fi
            }; done; exec 4>&-

            #If this tomcatid wasn't found in the check file then create a row for it.
            #This sets a false lastgood time of now but this only happens once, the first time check system sees this tomcatid.
            if [ "$foundtomcatidincheckfile" == "0"  ]; then
                CURRENTTIME=`date +%s`
                #Write a new record
                sed -i "
                /#BEGINDATA/ a\
                $TOMCATID:$CURRENTTIME
                " $CHECKTOMCATSFILE
            fi

		fi

	fi
}; done; exec 3>&-









