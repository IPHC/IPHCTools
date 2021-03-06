#!/bin/bash

##########################################################################
#                                                                        #
#  Description                                                           #
# =============                                                          #
#                                                                        #
# This script allow you to copy crab outputs located on DPM. It assumes  #
# that when running crab, you put in "user_remote_dir" something of the  #
# form :                                                                 #
#                                                                        #
#   user_remote_dir=prodName/taskName                                    #
#                                                                        #
# and that your outputs are now located in folders such as :             #
#                                                                        #
#   $DPM/yourName/prodName/taskName                                      #
#                                                                        #
# and you want to copy locally all the files in that folder starting by  #
# $TARGET (ex : NTuple_*).                                               #
#                                                                        #
# This script will create different folder 'taskName' in the current     #
# directory and copy all the files matching ${TARGET}_*.root.            #
#                                                                        #
# *BUT* it will ignore :                                                 #
#                                                                        #
#  * those that are already in the local folder and have the same size   #
#    as the remote file (allows to restart the script if it crashes, for #
#    instance because your proxy expired).                               #
#                                                                        #
#  * the duplicate files, ie the one with same crab job Id, but that are #
#    not the newest one (ie probably failed jobs). The script will copy  #
#    the newest version but ignore the older ones.                       #
#                                                                        #
#                                                                        #
#                                                                        #
#  Usage                                                                 #
# =======                                                                #
#                                                                        #
# * put an alias to this script in your .bashrc                          #
#                                                                        #
# * go to a directory where you want your harvesting to go               #
#                                                                        #
# * write a file named "harvestConfig" in this directory,                #
#   with the following structure :                                       #
#                                                                        #
# ------------------------------------------------                       #
# PRODNAME=February14-missingDatasets-v2                                 #
# TARGET=NTuple                                                          #
# TASKS="ttbar-semiLep ttbar-diLep"                                      #
#                                                                        #
# LOCAL_PWD=$PWD                                                         #
# DPM=/dpm/in2p3.fr/home/cms/phedex/store/user                           #
# CRAB_HOME=${DPM}/${USER}/${PRODNAME}                                   #
# ------------------------------------------------                       #
#                                                                        #
# * call this script with your alias                                     #
#                                                                        #
# * get coffee                                                           #
#                                                                        #
##########################################################################

# Read harvest config
source harvestConfig

if [[ $PRODNAME == "" ]]
then
    echo "Was unable to source the harvestConfig file ?"
    exit
fi

# Loop on tasks

for TASKNAME in $TASKS
do
    ################################################################
    # Create local folder and get list of content on remote folder #
    ################################################################

    mkdir -p $TASKNAME
    rm -f $TASKNAME/toBeHarvested.list

    rfdir $CRAB_HOME/$TASKNAME/ | grep ${TARGET} > $TASKNAME/rawDump
    RAWLIST=`cat $TASKNAME/rawDump | awk '{ print $9 }'`


    ########################################################
    # Parse the content to list what needs to be harvested #
    ########################################################

    echo "[${TASKNAME}] Parsing DPM files and checking sync with local files ..." | tee -a $TASKNAME/log

    # For each file in the list...
    for FILE in $RAWLIST
    do

        # Read the corresponding job number
        JOBNUMBER=`echo $FILE | sed 's|_| |g' | awk '{print $2}'`

        # Check that the file doesn't exist locally yet
        CHECK_SYNC=false
        if [[ -f $TASKNAME/$FILE ]]
        then
            # If it does exist locally, check that the size is the same as the remote file
            SIZE_FILE_ON_CRAB=`cat $TASKNAME/rawDump | grep $FILE | awk '{ print $5 }'`
            SIZE_FILE_LOCAL=`ls -l $TASKNAME/$FILE | awk '{print $5}'`
            if [[ $SIZE_FILE_ON_CRAB == $SIZE_FILE_LOCAL ]]
            then
                CHECK_SYNC=false
            else
                CHECK_SYNC=true
            fi
        else
            CHECK_SYNC=true
        fi

        # List all the files that have the same job number as this one
        OCCURENCES=`cat $TASKNAME/rawDump | awk '{print $9}' | grep ${TARGET}_${JOBNUMBER}_`
        # Count how many there are
        NOCCURENCES=`echo $OCCURENCES | wc -w`
        CHECK_DUPLIC=true

        # If there is at least two files with same job number
        if [[ $NOCCURENCES -ge 2 ]]
        then

            # Find the most recent one by looking at the date
            OCC_MOSTRECENT=""
            DATEINSEC_MOSTRECENT=0
            for OCC in $OCCURENCES
            do
                # God, this script is dirty
                DATE=`cat $TASKNAME/rawDump | grep $OCC | awk '{print $6 " " $7 " " $8}'`
                DATEINSEC=`date -d "$DATE" +'%s'`
                if [[ $DATEINSEC -gt $DATEINSEC_MOSTRECENT ]]
                then
                    OCC_MOSTRECENT=$OCC
                    DATEINSEC_MOSTRECENT=$DATEINSEC
                fi
            done

            # Check if the file we have now is the most recent occurence
            if [[ $FILE == $OCC_MOSTRECENT ]]
            then
                CHECK_DUPLIC=true
            else
                CHECK_DUPLIC=false
            fi

        fi

        # If we need to sync, and if this file
        # is the most recent ones among all the files with same job number...
        if [[ $CHECK_SYNC == true  ]]
        then
            if [[ $CHECK_DUPLIC == true  ]]
            then
                # Then add it to the files to be harvested
                echo $FILE >> $TASKNAME/toBeHarvested.list
            fi
        fi

    done

    rm -f $TASKNAME/rawDump

    ##########################################################
    # Perform an rfcp on each file that need to be harvested #
    ##########################################################

    rm -f $TASKNAME/log

    NCOPY=`cat $TASKNAME/toBeHarvested.list 2>/dev/null | wc -l`
    if [[ $NCOPY != 0 ]]
    then
        echo "[${TASKNAME}] $NCOPY files need to be harvested" | tee -a $TASKNAME/log
        echo "[${TASKNAME}] Starting copies ..." | tee -a $TASKNAME/log
        for FILE in `cat $TASKNAME/toBeHarvested.list`
        do
            echo "[$TASKNAME] Copying $FILE ... " | tee -a $TASKNAME/log
            rfcp $CRAB_HOME/$TASKNAME/$FILE ./$TASKNAME/ | tee -a $TASKNAME/log
        done
        echo "[${TASKNAME}] Done." | tee -a $TASKNAME/log
    else
        echo "[${TASKNAME}] No need to do anything" | tee -a $TASKNAME/log
    fi
done
