#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi


HOST=$1

./egg-mysql-stop.sh $HOST
ssh -t -t $HOST "sudo yum -y install mysql mysql-server"
ssh -t -t $HOST "sudo /sbin/chkconfig mysqld on"
./egg-mysql-start.sh $HOST
echo "sudo mysqladmin -u root password 'catalyst'"
ssh -t -t $HOST "sudo mysqladmin -u root password 'catalyst'"
echo "sudo mysqladmin flush-privileges"
ssh -t -t $HOST "sudo mysqladmin flush-privileges"
echo "sudo /usr/bin/mysql -u root -pcatalyst -e \"grant all on *.* to root@'%' identified by 'root'\""
ssh -t -t $HOST "sudo /usr/bin/mysql -u root -pcatalyst -e \"grant all on *.* to root@'%' identified by 'root'\""






#/usr/bin/mysql -u root -proot -e "grant all on *.* to root@'%' identified by 'root'"



#sudo mysql -u root -p
#mysql> DROP DATABASE test;                            [removes the test database]
#mysql> DELETE FROM mysql.user WHERE user = ;        [Removes anonymous access]
#mysql> FLUSH PRIVILEGES;


