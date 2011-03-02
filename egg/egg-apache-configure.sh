#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: APACHEID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a APACHEID"; exit; fi

APACHEID=$1

LOGICALINSTANCEID=""
#Read APACHESFILE to get LOGICALINSTANCEID
exec 3<> $APACHESFILE; while read inapacheline <&3; do {
	if [ $(echo "$inapacheline" | cut -c1) != "#" ]; then
		APACHEID_A=$(echo "$inapacheline" | cut -d ":" -f1)
		LOGICALINSTANCEID_A=$(echo "$inapacheline" | cut -d ":" -f2)
		if [ "$APACHEID_A" == "$APACHEID" ]; then
			LOGICALINSTANCEID=$LOGICALINSTANCEID_A		
		fi
	fi
}; done; exec 3>&-


HOST=""
#Read INSTANCESFILE... to get HOST  
exec 3<> $INSTANCESFILE; while read ininstancesline <&3; do {
	if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID_B=$(echo "$ininstancesline" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
		AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
		ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
		
		if [ "$LOGICALINSTANCEID_B" == "$LOGICALINSTANCEID" ]; then
		
			#Read AMAZONIIDSFILE
			AMAZONINSTANCEID=""
		    HOST=""
			exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
				if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
					LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
					if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
						AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
						HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
					fi
				fi
			}; done; exec 4>&-

		fi
	fi
}; done; exec 3>&-



#Now I know the LOGICALINSTANCEID and HOST of the Apache instance I'm supposed to be configuring.
#I need to iterate apps to find those that should be on this Apache.
#Along the way I'm building up VHOSTS with the VirtualHost config section(s)
VHOSTS=""
NEWLINE="\x0a"
exec 3<> $APPSFILE; while read inappsline <&3; do {
	if [ $(echo "$inappsline" | cut -c1) != "#" ]; then
		APPNAME=$(echo "$inappsline" | cut -d ":" -f1)
		APACHEID_C=$(echo "$inappsline" | cut -d ":" -f2)
		if [ "$APACHEID_C" == "$APACHEID" ]; then
		
			#This is an app that should be on this Apache
		
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"<VirtualHost *:80>"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"DocumentRoot /www/docs/$APPNAME"
			VHOSTS=$VHOSTS$NEWLINE
			
			BALANCEMEMBERS=""
			BALANCEMEMBERS=$BALANCEMEMBERS$NEWLINE
			
			PROXYPASSREVERSES=""
			PROXYPASSREVERSES=$PROXYPASSREVERSES$NEWLINE
			
			#Read TOMCATSFILE to find instances that should be on this Apache.
			exec 4<> $TOMCATSFILE; while read intomcatline <&4; do {
				if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
				
					TOMCATID_A=$(echo "$intomcatline" | cut -d ":" -f1)
					LOGICALINSTANCEID_TOMCAT=$(echo "$intomcatline" | cut -d ":" -f2)
					APPNAME_A=$(echo "$intomcatline" | cut -d ":" -f3)
					MEMMIN_A=$(echo "$intomcatline" | cut -d ":" -f4)
					MEMMAX_A=$(echo "$intomcatline" | cut -d ":" -f5)
					MAXTHREADS_A=$(echo "$intomcatline" | cut -d ":" -f6)
					HTTPPORT_A=$((8100+$TOMCATID_A))
				
					if [ "$APPNAME_A" == "$APPNAME" ]; then
						
						#This is a Tomcat instance that should be represented in this app's VirtualHost config

						ISFIRST="0";
						#Iterate urls.conf to get ServerAlias directives
						exec 5<> $URLSFILE; while read inurlsfile <&5; do {
							if [ $(echo "$inurlsfile" | cut -c1) != "#" ]; then
								APPNAME_B=$(echo "$inurlsfile" | cut -d ":" -f1)
								URL=$(echo "$inurlsfile" | cut -d ":" -f2)
								if [ "$APPNAME_B" == "$APPNAME" ]; then
									if [ $ISFIRST = "0" ]; then
										VHOSTS=$VHOSTS"ServerName "$URL
										VHOSTS=$VHOSTS$NEWLINE
									else
										VHOSTS=$VHOSTS"ServerAlias "$URL
										VHOSTS=$VHOSTS$NEWLINE
									fi
									ISFIRST="1"
								fi
							fi
						}; done; exec 5>&-

						#Flag, true if this tomcat host is found in amazoniids.conf
						TOMCATFOUND="false"
						
						#Read AMAZONIIDSFILE to get the HOST for this Tomcat
						exec 5<> $AMAZONIIDSFILE; while read amazoniidsline <&5; do {
							if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
								LOGICALINSTANCEID_D=$(echo "$amazoniidsline" | cut -d ":" -f1)
								if [ "$LOGICALINSTANCEID_D" == "$LOGICALINSTANCEID_TOMCAT" ]; then
									AMAZONINSTANCEID_TOMCAT=$(echo "$amazoniidsline" | cut -d ":" -f2)
									HOST_TOMCAT=$(echo "$amazoniidsline" | cut -d ":" -f3)
								    TOMCATFOUND="true"
								fi
							fi
						}; done; exec 5>&-
						
						if [ "$TOMCATFOUND" == "true" ]; then
                            #Build BalanceMember for this Tomcat
                            BALANCEMEMBERS=$BALANCEMEMBERS"BalancerMember http://$HOST_TOMCAT:$HTTPPORT_A route=node1 acquire=60000 smax=15 max=20 ttl=120 timeout=120 retry=60"
                            BALANCEMEMBERS=$BALANCEMEMBERS$NEWLINE

                            #Build ProxyPassReverse for this Tomcat
                            PROXYPASSREVERSES=$PROXYPASSREVERSES"ProxyPassReverse / http://$HOST_TOMCAT/"
                            PROXYPASSREVERSES=$PROXYPASSREVERSES$NEWLINE
						fi
					
					fi
				fi
			}; done; exec 4>&-
			
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"ProxyPass / balancer://$APPNAME/ stickysession=JSESSIONID|jsessionid maxattempts=4 lbmethod=byrequests timeout=120"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"<Proxy balancer://$APPNAME>"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"BrowserMatchNoCase slurp isrobot"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"BrowserMatchNoCase yandexbot isrobot"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"BrowserMatchNoCase msnbot isrobot"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"BrowserMatchNoCase MJ12bot isrobot"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"BrowserMatchNoCase Sosospider isrobot"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"BrowserMatchNoCase Exabot isrobot"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"BrowserMatchNoCase bingbot isrobot"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"deny from env=isrobot"	
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS$BALANCEMEMBERS
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"</Proxy>"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"ProxyPreserveHost On"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS$PROXYPASSREVERSES
			VHOSTS=$VHOSTS$NEWLINE
			
			VHOSTS=$VHOSTS"ErrorLog logs/$APPNAME-error_log"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"CustomLog logs/$APPNAME-access_log combinedshort"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"CustomLog logs/$APPNAME-referer_log referer"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"CustomLog logs/$APPNAME-agent_log agent"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"CustomLog logs/$APPNAME-instanceperformance_log instanceperformance"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"</VirtualHost>"
			VHOSTS=$VHOSTS$NEWLINE
			
		fi
	fi
}; done; exec 3>&-


HTTPDCONFTOUSE=conf/apache/default.httpd.conf
if [ -e conf/apache/apacheid$APACHEID.httpd.conf ]; then
	./log.sh "conf/apache/apacheid$APACHEID.httpd.conf exists"
    HTTPDCONFTOUSE=conf/apache/apacheid$APACHEID.httpd.conf
else
	./log.sh "conf/apache/apacheid$APACHEID.httpd.conf not found, using default httpd.conf"
fi



#Append the VHOSTS entry to the end of the file
rm -f data/apacheid$APACHEID.httpd.conf.tmp
cp $HTTPDCONFTOUSE data/apacheid$APACHEID.httpd.conf.tmp
echo -e "NameVirtualHost *:80" >> data/apacheid$APACHEID.httpd.conf.tmp
echo -e ${VHOSTS} >> data/apacheid$APACHEID.httpd.conf.tmp


#Download the latest remote file
rm -f data/apacheid$APACHEID.httpd.conf.remote
scp ec2-user@$HOST:/etc/httpd/conf/httpd.conf data/apacheid$APACHEID.httpd.conf.remote


#Determine whether this new config is different than the latest
if  diff data/apacheid$APACHEID.httpd.conf.tmp data/apacheid$APACHEID.httpd.conf.remote >/dev/null ; then
    ./log.sh "apacheid$APACHEID httpd.conf remote is SAME as local"
else
    ./log.sh "apacheid$APACHEID httpd.conf remote is DIFFERENT than local"

    #Copy latest to the remote Apache host
    scp data/apacheid$APACHEID.httpd.conf.tmp ec2-user@$HOST:httpd.conf.tmp
    ssh -t -t $HOST "sudo cp httpd.conf.tmp /etc/httpd/conf/httpd.conf"
    ssh -t -t $HOST "rm -f httpd.conf.tmp"

    #Make sure we have the latest locally
    scp ec2-user@$HOST:/etc/httpd/conf/httpd.conf data/apacheid$APACHEID.httpd.conf.remote

    #Bounce Apache
    ./egg-apache-stop.sh $HOST
    ./egg-apache-start.sh $HOST
fi

rm -f data/apacheid$APACHEID.httpd.conf.tmp



















