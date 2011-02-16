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
CHECKTOMCATSFILE=data/check.tomcats

if [ ! -f "$TOMCATSFILE" ]; then
  echo "Sorry, $TOMCATSFILE does not exist."
  exit 1
fi

if [ ! -f "$CHECKTOMCATSFILE" ]; then
  echo "$CHECKTOMCATSFILE does not exist so creating it."
  cp data/$CHECKTOMCATSFILE.sample $CHECKTOMCATSFILE
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
            HTTPPORT=$(echo "$intomcatline" | cut -d ":" -f6)
            MAXTHREADS=$(echo "$intomcatline" | cut -d ":" -f7)
            JVMROUTE=$APPNAME$TOMCATID


            #HTTP Check
            echo Start HTTP Check
            url="http://$HOST:$HTTPPORT/"
            retries=1
            timeout=60
            status=`wget -t 1 -T 60 $url 2>&1 | egrep "HTTP" | awk {'print $6'}`
            if [ "$status" == "200" ]; then
                echo "HTTP 200 response from $url, recording LASTGOOD"
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
                ./egg-log-status.sh "HTTP 200 fail"
            fi

            #This is max time that tomcat can be down before restart
            MAXLASTGOOD=180

            #Figure out how long since last good
            #Read CHECKTOMCATSFILE
            while read incheckline;
            do
                #Ignore lines that start with a comment hash mark
                if [ $(echo "$incheckline" | cut -c1) != "#" ]; then

                    TOMCATID_CHK=$(echo "$incheckline" | cut -d ":" -f1)

                    if [ "$TOMCATID_CHK" == "$TOMCATID" ]; then
                        LASTGOOD=$(echo "$incheckline" | cut -d ":" -f2)
                        CURRENTTIME=`date +%s`
                        LASTGOODSECONDSAGO=$((CURRENTTIME-LASTGOOD))
                        echo LASTGOODSECONDSAGO=$LASTGOODSECONDSAGO
                        if [ "${LASTGOODSECONDSAGO}" -gt "${MAXLASTGOOD}"  ]; then
                            ./egg-log-status.sh "$APP Tomcat http://$HOST:$HTTPPORT/ Down > $MAXLASTGOOD seconds"
                            ./egg-tomcat-stop.sh $HOST $APPDIR
                            ./egg-tomcat-start.sh $HOST $APPDIR $MEMMIN $MEMMAX
                            ./egg-log-status.sh "Sleeping 30 sec for $APP Tomcat$TOMCATID to come up"
                            sleep 30
                        fi
                    fi

                fi
            done < "$CHECKTOMCATSFILE"


		fi

	fi
done < "$TOMCATSFILE"









