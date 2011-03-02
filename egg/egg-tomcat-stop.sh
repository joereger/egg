#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APPDIR=$2

#Check for Existing Lock
TOMCATSTOPLOCKTIMEOUTSECONDS=120
source egg-tomcat-stop-lock.sh


if [ "$ISTOMCATSTOPLOCK" == "0"  ]; then


    #@TODO Before any stop attempt, verify that there's even a tomcat there in the first place!!
    tomcatcheck=`ssh $HOST "[ -d ./egg/$APPDIR/tomcat/ ] && echo 1"`
    if [ "$tomcatcheck" == 1 ]; then

        #Do the stop
        ./log-status.sh "Stopping Tomcat $APPDIR"
        #ssh -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"
        uselessjibberishvar=`ssh -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"`
        #ssh -t -t $HOST "cd egg/$APPDIR/tomcat/bin/; chmod 777 *.sh;"
        uselessjibberishvar=`ssh $HOST "cd egg/$APPDIR/tomcat/bin/; chmod 777 *.sh;"`
        ./log.sh "Tomcat $APPDIR Catalina shutdown.sh calling then waiting 5 sec"
        uselessjibberishvar=`ssh $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; export JRE_HOME=/usr/lib/jvm/jre; bash egg/$APPDIR/tomcat/bin/shutdown.sh"`
        sleep 5

        export tcdone="false"
        export tccount=0
        while [ $tcdone == "false" ]
        do
            tcprocesschk=`ssh $HOST "[ -n \"\\\`ps ax | grep egg/${APPDIR}/tomcat/conf | grep -v grep\\\`\" ] && echo 1"`
            ./log.sh "tcprocesschk=$tcprocesschk"
            if [ "$tcprocesschk" == 1 ]; then
                #Have to use ps to grab the PID... couldn't get onto one line
                PID=`ssh $HOST "ps -ef | grep egg/${APPDIR}/tomcat/conf | grep -v grep | awk '{print \\$2}' "`
                ./log.sh "Tomcat ${APPDIR} process running (try $tccount), sending kill -9 to PID $PID then waiting 5 sec"
                ssh -t -t $HOST "sudo kill -9 $PID"
                sleep 5
                tccount=$(( $tccount + 1 ))
                if [ "$tccount" == "15" ]; then
                    export tcdone="true"
                    ./log-status-red.sh "Tomcat ${APPDIR} process shutdown FAIL"
                fi
            else
                ./log.sh "Tomcat ${APPDIR} process not found"
                export tcdone="true"
            fi
        done
    else
        ./log.sh "Tomcat ${APPDIR}/tomcat/ directory not found so nothing to stop"
    fi





fi


