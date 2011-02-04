#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi


HOST=$1

./egg-apache-stop.sh $HOST
ssh -t -t $HOST "sudo yum -y install mysql mysql-server"
ssh -t -t $HOST "sudo /sbin/chkconfig mysqld on"
ssh -t -t $HOST "sudo /sbin/service mysqld start"
ssh -t -t $HOST "sudo mysqladmin -u root password 'catalyst'"


#/usr/bin/mysql -u root -proot -e "grant all on *.* to root@'%' identified by 'root'"



#sudo mysql -u root -p
#mysql> DROP DATABASE test;                            [removes the test database]
#mysql> DELETE FROM mysql.user WHERE user = ;        [Removes anonymous access]
#mysql> FLUSH PRIVILEGES;


