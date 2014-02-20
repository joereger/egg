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

./pulse-update.sh "Apache$APACHEID" "CONFIGURATION BEGINNING"


#SSL - Key/Cert need to be named as below
#/conf/default/apache/apacheid1.ssl.public.crt
#/conf/default/apache/apacheid1.ssl.private.key
#/conf/default/apache/apacheid1.ssl.intermediate.crt
DOSSL="0"
if [ -e $CONFDIR/apache/apacheid$APACHEID.ssl.public.crt ]; then
    if [ -e $CONFDIR/apache/apacheid$APACHEID.ssl.private.key ]; then
        if [ -e $CONFDIR/apache/apacheid$APACHEID.ssl.intermediate.crt ]; then

            DOSSL="1"
            ./log.sh "$CONFDIR/apache/apacheid$APACHEID.ssl.public.crt, private.key and intermediate.crt exist"
            ./pulse-update.sh "Apache$APACHEID" "CONFIGURING, SSL FILES FOUND"

            scp $CONFDIR/apache/apacheid$APACHEID.ssl.public.crt ec2-user@$HOST:apacheid$APACHEID.ssl.public.crt
            ssh -t -t $HOST "sudo cp apacheid$APACHEID.ssl.public.crt /etc/httpd/conf/apacheid$APACHEID.ssl.public.crt"
            ssh -t -t $HOST "rm -f apacheid$APACHEID.ssl.public.crt"

            scp $CONFDIR/apache/apacheid$APACHEID.ssl.private.key ec2-user@$HOST:apacheid$APACHEID.ssl.private.key
            ssh -t -t $HOST "sudo cp apacheid$APACHEID.ssl.private.key /etc/httpd/conf/apacheid$APACHEID.ssl.private.key"
            ssh -t -t $HOST "rm -f apacheid$APACHEID.ssl.private.key"

            scp $CONFDIR/apache/apacheid$APACHEID.ssl.intermediate.crt ec2-user@$HOST:apacheid$APACHEID.ssl.intermediate.crt
            ssh -t -t $HOST "sudo cp apacheid$APACHEID.ssl.intermediate.crt /etc/httpd/conf/apacheid$APACHEID.ssl.intermediate.crt"
            ssh -t -t $HOST "rm -f apacheid$APACHEID.ssl.intermediate.crt"

        fi
    fi
else
	./log.sh "$CONFDIR/apache/apacheid$APACHEID.ssl. certs and/or keys not found"
	./pulse-update.sh "Apache$APACHEID" "CONFIGURING, NO SSL FILES FOUND"
fi



#Now I know the LOGICALINSTANCEID and HOST of the Apache instance I'm supposed to be configuring.
#I need to iterate apps to find those that should be on this Apache.
#Along the way I'm building up VHOSTS with the VirtualHost config section(s)
VHOSTS=""
VHOSTSSL=""
NEWLINE="\x0a"
exec 3<> $APPSFILE; while read inappsline <&3; do {
	if [ $(echo "$inappsline" | cut -c1) != "#" ]; then
		APPNAME=$(echo "$inappsline" | cut -d ":" -f1)
		APACHEID_C=$(echo "$inappsline" | cut -d ":" -f2)
		if [ "$APACHEID_C" == "$APACHEID" ]; then
		
			#This is an app that should be on this Apache
		    ./log.sh "$APPNAME will be added to this Apache config"

			VHOSTS=$VHOSTS$NEWLINE"<VirtualHost *:80>"
			VHOSTSSL=$VHOSTSSL$NEWLINE"<VirtualHost *:443>"

			VHOSTS=$VHOSTS$NEWLINE"DocumentRoot /www/docs/$APPNAME"$NEWLINE
			VHOSTSSL=$VHOSTSSL$NEWLINE"DocumentRoot /www/docs/$APPNAME"$NEWLINE


			#Start SSL-heavy section
			VHOSTSSL=$VHOSTSSL$NEWLINE"SSLEngine on"
			VHOSTSSL=$VHOSTSSL$NEWLINE"SSLCertificateFile /etc/httpd/conf/apacheid$APACHEID.ssl.public.crt"
			VHOSTSSL=$VHOSTSSL$NEWLINE"SSLCertificateKeyFile /etc/httpd/conf/apacheid$APACHEID.ssl.private.key"
			VHOSTSSL=$VHOSTSSL$NEWLINE"SSLCertificateChainFile /etc/httpd/conf/apacheid$APACHEID.ssl.intermediate.crt"
			#End SSL-heavy section


			
			BALANCEMEMBERS=""
			BALANCEMEMBERS=$BALANCEMEMBERS$NEWLINE
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
					JVMROUTE=$APPNAME$TOMCATID_A
				
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
										VHOSTS=$VHOSTS$NEWLINE"ServerName "$URL$NEWLINE
                                        VHOSTSSL=$VHOSTSSL$NEWLINE"ServerName "$URL$NEWLINE
									else
										VHOSTS=$VHOSTS$NEWLINE"ServerAlias "$URL$NEWLINE
										VHOSTSSL=$VHOSTSSL$NEWLINE"ServerAlias "$URL$NEWLINE
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
                            BALANCEMEMBERS=$BALANCEMEMBERS"BalancerMember http://$HOST_TOMCAT:$HTTPPORT_A route=$JVMROUTE acquire=60000 smax=5 max=10 ttl=120 timeout=120 retry=60 loadfactor=1"
                            BALANCEMEMBERS=$BALANCEMEMBERS$NEWLINE

                            #Build ProxyPassReverse for this Tomcat
                            PROXYPASSREVERSES=$PROXYPASSREVERSES"ProxyPassReverse / http://$HOST_TOMCAT/"
                            PROXYPASSREVERSES=$PROXYPASSREVERSES$NEWLINE
						fi
					
					fi
				fi
			}; done; exec 4>&-
			

			VHOSTS=$VHOSTS$NEWLINE$NEWLINE"ProxyPass / balancer://$APPNAME/ stickysession=JSESSIONID|jsessionid maxattempts=4 lbmethod=byrequests timeout=120"
			VHOSTSSL=$VHOSTSSL$NEWLINE$NEWLINE"ProxyPass / balancer://$APPNAME/ stickysession=JSESSIONID|jsessionid maxattempts=4 lbmethod=byrequests timeout=120"

			VHOSTS=$VHOSTS$NEWLINE"<Proxy balancer://$APPNAME>"
			VHOSTSSL=$VHOSTSSL$NEWLINE"<Proxy balancer://$APPNAME>"

			VHOSTS=$VHOSTS$NEWLINE"BrowserMatchNoCase baidu isrobot"
			VHOSTSSL=$VHOSTSSL$NEWLINE"BrowserMatchNoCase baidu isrobot"

			VHOSTS=$VHOSTS$NEWLINE"BrowserMatchNoCase slurp isrobot"
			VHOSTSSL=$VHOSTSSL$NEWLINE"BrowserMatchNoCase slurp isrobot"

			VHOSTS=$VHOSTS$NEWLINE"BrowserMatchNoCase yandexbot isrobot"
			VHOSTSSL=$VHOSTSSL$NEWLINE"BrowserMatchNoCase yandexbot isrobot"

			VHOSTS=$VHOSTS$NEWLINE"BrowserMatchNoCase MJ12bot isrobot"
			VHOSTSSL=$VHOSTSSL$NEWLINE"BrowserMatchNoCase MJ12bot isrobot"

			VHOSTS=$VHOSTS$NEWLINE"BrowserMatchNoCase Sosospider isrobot"
			VHOSTSSL=$VHOSTSSL$NEWLINE"BrowserMatchNoCase Sosospider isrobot"

			VHOSTS=$VHOSTS$NEWLINE"BrowserMatchNoCase Exabot isrobot"
			VHOSTSSL=$VHOSTSSL$NEWLINE"BrowserMatchNoCase Exabot isrobot"

			VHOSTS=$VHOSTS$NEWLINE"deny from env=isrobot"
			VHOSTSSL=$VHOSTSSL$NEWLINE"deny from env=isrobot"

			VHOSTS=$VHOSTS$NEWLINE"deny from 10.210.7.159"
			VHOSTSSL=$VHOSTSSL$NEWLINE"deny from 10.210.7.159"

			VHOSTS=$VHOSTS$NEWLINE$BALANCEMEMBERS
			VHOSTSSL=$VHOSTSSL$NEWLINE$BALANCEMEMBERS

			VHOSTS=$VHOSTS$NEWLINE"</Proxy>"
			VHOSTSSL=$VHOSTSSL$NEWLINE"</Proxy>"

			VHOSTS=$VHOSTS$NEWLINE$NEWLINE"ProxyPreserveHost On"
			VHOSTSSL=$VHOSTSSL$NEWLINE$NEWLINE"ProxyPreserveHost On"

			VHOSTS=$VHOSTS$NEWLINE$PROXYPASSREVERSES
			VHOSTSSL=$VHOSTSSL$NEWLINE$PROXYPASSREVERSES

			VHOSTS=$VHOSTS$NEWLINE"ErrorLog logs/$APPNAME-error_log"
			VHOSTSSL=$VHOSTSSL$NEWLINE"ErrorLog logs/$APPNAME-error_log"

			VHOSTS=$VHOSTS$NEWLINE"CustomLog logs/$APPNAME-access_log combinedshort"
			VHOSTSSL=$VHOSTSSL$NEWLINE"CustomLog logs/$APPNAME-access_log combinedshort"

			VHOSTS=$VHOSTS$NEWLINE"CustomLog logs/$APPNAME-referer_log referer"
			VHOSTSSL=$VHOSTSSL$NEWLINE"CustomLog logs/$APPNAME-referer_log referer"

			VHOSTS=$VHOSTS$NEWLINE"CustomLog logs/$APPNAME-agent_log agent"
			VHOSTSSL=$VHOSTSSL$NEWLINE"CustomLog logs/$APPNAME-agent_log agent"

			VHOSTS=$VHOSTS$NEWLINE"CustomLog logs/$APPNAME-instanceperformance_log instanceperformance"
			VHOSTSSL=$VHOSTSSL$NEWLINE"CustomLog logs/$APPNAME-instanceperformance_log instanceperformance"

			VHOSTS=$VHOSTS$NEWLINE"</VirtualHost>"$NEWLINE
			VHOSTSSL=$VHOSTSSL$NEWLINE"</VirtualHost>"$NEWLINE


		else
		    ./log.sh "$APPNAME won't be added to this Apache config"
		fi
	fi
}; done; exec 3>&-




#Find the base httpd.conf to use
HTTPDCONFTOUSE=$CONFDIR/apache/default.httpd.conf
if [ -e $CONFDIR/apache/apacheid$APACHEID.httpd.conf ]; then
	./log.sh "$CONFDIR/apache/apacheid$APACHEID.httpd.conf exists"
	./pulse-update.sh "Apache$APACHEID" "CONFIGURING, USING APACHEID$APACHEID.HTTPD.CONF"
    HTTPDCONFTOUSE=$CONFDIR/apache/apacheid$APACHEID.httpd.conf
else
	./log.sh "$CONFDIR/apache/apacheid$APACHEID.httpd.conf not found, using default httpd.conf"
	./pulse-update.sh "Apache$APACHEID" "CONFIGURING, USING DEFAULT HTTPD.CONF"
fi


#Append the VHOSTS entry to the end of the file
rm -f data/apacheid$APACHEID.httpd.conf.tmp
cp $HTTPDCONFTOUSE data/apacheid$APACHEID.httpd.conf.tmp
#echo -e "NameVirtualHost *:80" >> data/apacheid$APACHEID.httpd.conf.tmp
echo -e ${VHOSTS} >> data/apacheid$APACHEID.httpd.conf.tmp
#SSL
#If SSL is on we need to create a :443 VirtualHost
if [ "$DOSSL" == "1" ]; then
    ./log.sh "DOSSL is 1 so Creating :443 VirtualHost"
    ./pulse-update.sh "Apache$APACHEID" "CONFIGURING, DOSSL=1, APPENDING SSL"
    #echo -e "NameVirtualHost *:443" >> data/apacheid$APACHEID.httpd.conf.tmp
    echo -e ${VHOSTSSL} >> data/apacheid$APACHEID.httpd.conf.tmp
else
    ./log.sh "DOSSL NOT 1 so NOT Creating :443 VirtualHost"
    ./pulse-update.sh "Apache$APACHEID" "CONFIGURING, DOSSL=0, NOT APPENDING SSL"
fi




#Download the latest remote file
rm -f data/apacheid$APACHEID.httpd.conf.remote
scp ec2-user@$HOST:/etc/httpd/conf/httpd.conf data/apacheid$APACHEID.httpd.conf.remote


#Determine whether this new config is different than the latest
if  diff data/apacheid$APACHEID.httpd.conf.tmp data/apacheid$APACHEID.httpd.conf.remote >/dev/null ; then
    ./log.sh "apacheid$APACHEID httpd.conf remote is SAME as local"
else
    ./log.sh "apacheid$APACHEID httpd.conf remote is DIFFERENT than local"
    ./pulse-update.sh "Apache$APACHEID" "httpd.conf remote DIFFERENT than local, copying"
    #Copy latest to the remote Apache host
    scp data/apacheid$APACHEID.httpd.conf.tmp ec2-user@$HOST:httpd.conf.tmp
    ssh -t -t $HOST "sudo cp httpd.conf.tmp /etc/httpd/conf/httpd.conf"
    ssh -t -t $HOST "rm -f httpd.conf.tmp"

    #Make sure we have the latest locally
    scp ec2-user@$HOST:/etc/httpd/conf/httpd.conf data/apacheid$APACHEID.httpd.conf.remote

    #Bounce Apache
    ./pulse-update.sh "Apache$APACHEID" "Bouncing to update config"
    ./egg-apache-stop.sh $HOST
    ./egg-apache-start.sh $HOST
    ./pulse-update.sh "Apache$APACHEID" "Done bouncing to update config"
fi

rm -f data/apacheid$APACHEID.httpd.conf.tmp

./pulse-update.sh "Apache$APACHEID" "CONFIGURATION COMPLETE"



















