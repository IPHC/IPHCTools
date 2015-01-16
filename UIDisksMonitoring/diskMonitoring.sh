#!/bin/bash

while read line
do
    DISK_TAG=`echo $line | tr ',' ' ' | awk '{print $1}'`
    DISK_PATH=`echo $line | tr ',' ' ' | awk '{print $2}'`
    
    echo "Checking $DISK_TAG ..."
   
    DF_OUTPUT=`df --block-size=G $DISK_PATH | tail -n1 | cut -c23-`
    TOTAL_SIZE=`echo $DF_OUTPUT | awk '{print $1}' | sed 's/G//g'`
    FREE_SIZE=`echo $DF_OUTPUT | awk '{print $3}' | sed 's/G//g'`

    du -s --block-size=G $DISK_PATH/* > tmp 2>/dev/null

    mkdir -p data/tmp/
    rm -f data/tmp/${DISK_TAG}.usage
    TOTAL_USAGE=0
    while read line
    do
        USER_NAME=`echo $line | awk '{print $2}'`
        USER_NAME=`basename $USER_NAME`
        USER_USAGE=`echo $line | awk '{print $1}' | sed 's/G//g'`

        echo "$USER_NAME,$USER_USAGE" >> data/tmp/${DISK_TAG}.usage

        TOTAL_USAGE=$((TOTAL_USAGE + USER_USAGE))
    done < tmp

    UNKNOWN_SIZE=$((TOTAL_SIZE - FREE_SIZE - TOTAL_USAGE))

    echo "unknown,$UNKNOWN_SIZE" >> data/tmp/${DISK_TAG}.usage
    echo "free,$FREE_SIZE"       >> data/tmp/${DISK_TAG}.usage

done < config/monitoredFolders.cfg

rm -f tmp
DATE=`date +%Y_%m_%d_%H:%M:%S`
mv data/tmp/ data/historyUse/$DATE/
rm data/currentUse
ln -s historyUse/$DATE/ data/currentUse

while read line
do

    DISK_TAG=`echo $line | tr ',' ' ' | awk '{print $1}'`
    DISK_PATH=`echo $line | tr ',' ' ' | awk '{print $2}'`
    
    echo "Writing history summary for $DISK_TAG ..."

    DF_OUTPUT=`df --block-size=G $DISK_PATH | tail -n1 | cut -c23-`
    TOTAL_SIZE=`echo $DF_OUTPUT | awk '{print $1}' | sed 's/G//g'`
    FREE_SIZE=`echo $DF_OUTPUT | awk '{print $3}' | sed 's/G//g'`

    rm -f data/historySummary/$DISK_TAG.history
    for HISTORY in `ls data/historyUse`
    do
        DATE=`echo $HISTORY | tr '_' ' ' | awk '{print $1 "/" $2 "/" $3 " " $4}'`
        SHORT_DATE=`date --date="$DATE" +%b%d`
        FREE=`cat data/historyUse/$HISTORY/$DISK_TAG.usage | grep free | tr ',' ' ' | awk '{print $2}'`
        echo "$SHORT_DATE,$FREE" >> data/historySummary/$DISK_TAG.history
    done

done < config/monitoredFolders.cfg




