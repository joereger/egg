#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: APACHEID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a APACHEID"; exit; fi

APACHEID=$1

APACHESFILE=conf/apaches.conf
INSTANCESFILE=conf/instances.conf
TOMCATSFILE=conf/tomcats.conf
URLSFILE=conf/urls.conf
APPSFILE=conf/apps.conf
AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi

if [ ! -f "$APACHESFILE" ]; then
  echo "Sorry, $APACHESFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

if [ ! -f "$TOMCATSFILE" ]; then
  echo "Sorry, $TOMCATSFILE does not exist."
  exit 1
fi

if [ ! -f "$URLSFILE" ]; then
  echo "Sorry, $URLSFILE does not exist."
  exit 1
fi

if [ ! -f "$APPSFILE" ]; then
  echo "Sorry, $APPSFILE does not exist."
  exit 1
fi

LOGICALINSTANCEID=""
#Read APACHESFILE to get LOGICALINSTANCEID
while read inapacheline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$inapacheline" | cut -c1) != "#" ]; then
		APACHEID_A=$(echo "$inapacheline" | cut -d ":" -f1)
		LOGICALINSTANCEID_A=$(echo "$inapacheline" | cut -d ":" -f2)
		if [ "$APACHEID_A" == "$APACHEID" ]; then
			LOGICALINSTANCEID=$LOGICALINSTANCEID_A		
		fi
	fi
done < "$APACHESFILE"


HOST=""
#Read INSTANCESFILE... to get HOST  
while read ininstancesline;
do
	#Ignore lines that start with a comment hash mark
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
			while read amazoniidsline;
			do
				#Ignore lines that start with a comment hash mark
				if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
					LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
					if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
						AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
						HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
					fi
				fi
			done < "$AMAZONIIDSFILE"

		fi
	fi
done < "$INSTANCESFILE"



#Now I know the LOGICALINSTANCEID and HOST of the Apache instance I'm supposed to be configuring.
#I need to iterate apps to find those that should be on this Apache.
#Along the way I'm building up VHOSTS with the VirtualHost config section(s)
VHOSTS=""
NEWLINE="\x0a"
while read inappsline;
do
	#Ignore lines that start with a comment hash mark
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
			while read intomcatline;
			do
				#Ignore lines that start with a comment hash mark
				if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
				
					TOMCATID_A=$(echo "$intomcatline" | cut -d ":" -f1)
					LOGICALINSTANCEID_TOMCAT=$(echo "$intomcatline" | cut -d ":" -f2)
					APPNAME_A=$(echo "$intomcatline" | cut -d ":" -f3)
					MEMMIN_A=$(echo "$intomcatline" | cut -d ":" -f4)
					MEMMAX_A=$(echo "$intomcatline" | cut -d ":" -f5)
					HTTPPORT_A=$(echo "$intomcatline" | cut -d ":" -f6)
					MAXTHREADS_A=$(echo "$intomcatline" | cut -d ":" -f7)
				
					if [ "$APPNAME_A" == "$APPNAME" ]; then
						
						#This is a Tomcat instance that should be represented in this app's VirtualHost config

						ISFIRST="0";
						#Iterate urls.conf to get ServerAlias directives
						while read inurlsline;
						do
							#Ignore lines that start with a comment hash mark
							if [ $(echo "$inurlsline" | cut -c1) != "#" ]; then
								APPNAME_B=$(echo "$inurlsline" | cut -d ":" -f1)
								URL=$(echo "$inurlsline" | cut -d ":" -f2)
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
						done < "$URLSFILE"

						#Flag, true if this tomcat host is found in amazoniids.conf
						TOMCATFOUND="false"
						
						#Read AMAZONIIDSFILE to get the HOST for this Tomcat
						while read amazoniidsline;
						do
							#Ignore lines that start with a comment hash mark
							if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
								LOGICALINSTANCEID_D=$(echo "$amazoniidsline" | cut -d ":" -f1)
								if [ "$LOGICALINSTANCEID_D" == "$LOGICALINSTANCEID_TOMCAT" ]; then
									AMAZONINSTANCEID_TOMCAT=$(echo "$amazoniidsline" | cut -d ":" -f2)
									HOST_TOMCAT=$(echo "$amazoniidsline" | cut -d ":" -f3)
								    TOMCATFOUND="true"
								fi
							fi
						done < "$AMAZONIIDSFILE"
						
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
			done < "$TOMCATSFILE"
			
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
			VHOSTS=$VHOSTS"TransferLog logs/$APPNAME-access_log"
			VHOSTS=$VHOSTS$NEWLINE
			VHOSTS=$VHOSTS"</VirtualHost>"
			VHOSTS=$VHOSTS$NEWLINE
			
		fi
	fi
done < "$APPSFILE"


HTTPDCONFTOUSE=conf/apache/default.httpd.conf
if [ -e conf/apache/apacheid$APACHEID.httpd.conf ]; then
	./log.sh "conf/apache/apacheid$APACHEID.httpd.conf exists"
    HTTPDCONFTOUSE=conf/apache/apacheid$APACHEID.httpd.conf
else
	./log.sh "conf/apache/apacheid$APACHEID.httpd.conf not found, using default httpd.conf"
fi



#Append the VHOSTS entry to the end of the file
cp $HTTPDCONFTOUSE data/apacheid$APACHEID.httpd.conf.tmp
echo -e "NameVirtualHost *:80" >> data/apacheid$APACHEID.httpd.conf.tmp
echo -e ${VHOSTS} >> data/apacheid$APACHEID.httpd.conf.tmp

#Determine whether this new config is different than the latest
if  diff data/apacheid$APACHEID.httpd.conf.tmp data/apacheid$APACHEID.httpd.conf.latest >/dev/null ; then
    ./log.sh "apacheid$APACHEID.httpd.conf.tmp is the same as apacheid$APACHEID.httpd.conf.latest"
else
    ./log.sh "apacheid$APACHEID.httpd.conf.tmp is different than apacheid$APACHEID.httpd.conf.tmp"
    #Promote .tmp to .latest
    cp data/apacheid$APACHEID.httpd.conf.tmp data/apacheid$APACHEID.httpd.conf.latest

    #Copy latest to the remote Apache host
    scp data/apacheid$APACHEID.httpd.conf.latest ec2-user@$HOST:httpd.conf.tmp
    ssh -t -t $HOST "sudo cp httpd.conf.tmp /etc/httpd/conf/httpd.conf"
    ssh -t -t $HOST "rm -f httpd.conf.tmp"

    #Bounce Apache
    ./egg-apache-stop.sh $HOST
    ./egg-apache-start.sh $HOST
fi

rm -f data/apacheid$APACHEID.httpd.conf.tmp


















