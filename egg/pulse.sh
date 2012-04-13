#!/bin/bash

export DONTREDITSTDOUTTOLOGFILE=1
source common.sh



export outerdone="false"
while [ $outerdone == "false" ]
do



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

    ROWS=$(( $ROWS + 1 ))
    tput cup $ROWS 0
    echo "TOMCATS__________________________"


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

    ROWS=$(( $ROWS + 1 ))
    tput cup $ROWS 0
    echo "INSTANCES________________________"

    exec 3<> $INSTANCESFILE; while read ininstancesline <&3; do {
        if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
            LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
            ROWS=$(( $ROWS + 1 ))
            tput cup $ROWS 1
            tput el
            echo "Instance$LOGICALINSTANCEID"
            KEY="Instance$LOGICALINSTANCEID"
            hput rows $KEY $ROWS
            hput cols $KEY 20
        fi
    }; done; exec 3>&-





    ROWS=$(( $ROWS + 1 ))
    tput cup $ROWS 0
    echo "MYSQLS___________________________"

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


    ROWS=$(( $ROWS + 1 ))
    tput cup $ROWS 0
    echo "MONGODBS___________________________"

    exec 3<> $MONGODBSFILE; while read inmongodbs <&3; do {
        if [ $(echo "$inmongodbs" | cut -c1) != "#" ]; then
            MYSQLID=$(echo "$inmongodbs" | cut -d ":" -f1)
            ROWS=$(( $ROWS + 1 ))
            tput cup $ROWS 1
            tput el
            echo "MONGODB$MYSQLID"
            KEY="MONGODB$MYSQLID"
            hput rows $KEY $ROWS
            hput cols $KEY 20
        fi
    }; done; exec 3>&-


    ROWS=$(( $ROWS + 1 ))
    tput cup $ROWS 0
    echo "MISC_____________________________"


    ROWS=$(( $ROWS + 1 ))
    tput cup $ROWS 1
    echo "Egg"
    KEY="Egg"
    hput rows $KEY $ROWS
    hput cols $KEY 20

    ROWS=$(( $ROWS + 1 ))
    tput cup $ROWS 1
    echo "Cron"
    KEY="Cron"
    hput rows $KEY $ROWS
    hput cols $KEY 20

    ROWS=$(( $ROWS + 1 ))
    tput cup $ROWS 1
    echo "VerifyUp"
    KEY="VerifyUp"
    hput rows $KEY $ROWS
    hput cols $KEY 20

    ROWS=$(( $ROWS + 1 ))
    tput cup $ROWS 1
    echo "CronOn"
    KEY="CronOn"
    hput rows $KEY $ROWS
    hput cols $KEY 20


    exec 3<> $APACHESFILE; while read inapache <&3; do {
        if [ $(echo "$inapache" | cut -c1) != "#" ]; then
            APACHEID=$(echo "$inapache" | cut -d ":" -f1)
            ROWS=$(( $ROWS + 1 ))
            tput cup $ROWS 1
            tput el
            echo "Apache$APACHEID"
            KEY="Apache$APACHEID"
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





    #========================================
    #========================================
    #This is the loop that updates the screen
    #========================================
    COUNT=0
    export done="false"
    while [ $done == "false" ]
    do
        exec 3<> $PULSEFILE; while read pulseline <&3; do {
            if [ $(echo "$pulseline" | cut -c1) != "#" ]; then
                KEY=$(echo "$pulseline" | cut -d ":" -f1)
                VALUE=$(echo "$pulseline" | cut -d ":" -f2)
                ROW=`hget rows "$KEY"`
                COL=`hget cols "$KEY"`


                #Sometimes (often) hget returns "grep: /tmp/ file not found" or funky chars
                #So need to check that ROW and COL are numeric
                if [[ $ROW =~ ^[0-9]+$ ]]; then
                if [[ $COL =~ ^[0-9]+$ ]]; then

                                tput cup $ROW $COL
                                tput el
                                if [ "${VALUE:0:2}" = "OK" ]; then
                                    echo -e ${cf_green}${VALUE}${c_reset}
                                else
                                    echo -e ${cb_red}${VALUE}${c_reset}
                                fi
                fi
                fi

            fi
        }; done; exec 3>&-

        COUNT=$(( $COUNT + 1 ))
        if [ "$COUNT" == "120" ]; then
            done="true"
        fi

        sleep 5
    done
    #========================================
    #========================================


done









