#!/bin/bash


#rm -f speedtest.data
#rm -f speedtest.zip

STARTTIME=$(date +%s.%N)

#for i in {1..500}
#do
#   echo "Yo, file being written at `date`" >> speedtest.data
#done

#ENDInt=$(date +%s.%N)
#DIFF=$(echo "$ENDInt - $STARTTIME" | bc)
#echo Done Writing $DIFF


for i in {1..100000}
do
   TMPVAR=$((i/3))
done

#ENDInt2=$(date +%s.%N)
#DIFF=$(echo "$ENDInt2 - $STARTTIME" | bc)
#echo Done Looping $DIFF

#zip -q speedtest.zip speedtest.data

#rm speedtest.data
#rm speedtest.zip

END=$(date +%s.%N)


# echo $START
# echo $END
DIFF=$(echo "$END - $STARTTIME" | bc)
echo $DIFF

#Single Line Version
#STARTTIME=$(date +%s.%N); for i in {1..100000}; do TMPVAR=$((i/3)); done; END=$(date +%s.%N); DIFF=$(echo "$END - $STARTTIME" | bc); echo $DIFF