#!/bin/bash


####################################################################
#                                                                  #
#  Author : Alex. Aubin @ IPHC Strasbourg, 2014                    #
#                                                                  #
#  Disclaimer                                                      #
# ============                                                     #
#                                                                  #
# - "Each time you duplicate code, god kills a kitten."            #
#   To avoid duplicating this script everywhere you need it,       #
#   put a simple alias in your .bashrc. It'll be easier if you     #
#   need to update this file.                                      #
#                                                                  #
# - Even though this tool allows to easily deal with a massive     #
#   number of crab task, you should keep using your brain and not  #
#   blindly automatically resubmit tasks whom >50% job crashed.    #
#   It probably means you're doing something wrong, and wasting    #
#   grid time.                                                     #
#                                                                  #
#  Usage                                                           #
# =======                                                          #
#  see "octopus -h"                                                #
#                                                                  #
####################################################################

###################
# Parsing options #
###################

printHelp="false"
generateConfig="false"
update="false"
errorReport="false"
resubmit="false"
inputTasks="false"
statusReport="false"
ignoreClear="false"

OPTIONS=`getopt -o "hG:T:SUERI" --long "help generateConfig: tasks: status update errors resubmit ignoreClear" -n octopus -- "$@"`
eval set -- "$OPTIONS"
while true
do
    case "$1" in
        -h | -H | --help)       printHelp="true";      shift ;;
        -G | --generateConfig)  generateConfig="true"; PRODNAME="$2"; shift 2 ;;
        -T | --tasks)           inputTasks="true";     TASKS="$2"; shift 2 ;;
        -S | --status)          statusReport="true";   shift ;;
        -U | --update)          update="true";         shift ;;
        -E | --errors)          errorReport="true";    shift ;;
        -R | --resubmit)        resubmit="true";       shift ;;
        -I | --ignoreClear)     ignoreClear="true";    shift ;;
        -- ) shift; break;;
        *  ) break;;
    esac
done

########
# Help #
########

if [[ $printHelp == "true" ]]
then
    echo "
  Octopus
 ---------
 Tool to monitor and manage multiple crab tasks from command-line.                                                 

 By default, the list of task to consider is detected automatically from the crab folders in the current directory.
 You can also ignore some tasks by listing them in a file named .octopusIgnore.                                  
 NB: if -U option is not specified, the job status are not automatically updated since the last octopus -U.        

 Usage: octopus <[options]>
 Options:
        -H  --help                           Print this help, duh.
        -G  --generateConfig ProdName        Generate a multicrab.cfg file based on multicrab.list listing the crab task 
                                             name in first column and dataset name in second column. 
        -T  --tasks          \"Task1 Task2\"   Specify the list of tasks to monitor instead of automatic detection.
        -S  --status                         Show a status report of the tasks.
        -U  --update                         Update the status (crab -status) for each task before the status report.
        -E  --errors                         Show a summary of the error/crash reasons.
        -R  --resubmit                       Ask crab to resubmit each task with a faulty status.
        -I  --ignoreClear                    With option -S, add tasks with 100% clear completion to the .octopusIgnore
    "
    exit
fi

########################
# Generate config file #
########################
        
if [[ $generateConfig == "true" ]]
then

    echo "[MULTICRAB]"
    echo "cfg=crab.cfg"
    echo ""
    echo "[COMMON]"
    echo ""

    cat multicrab.list | while read LINE ; 
    do
        NAME=`echo $LINE | awk '{print $1}'`
        DATASET=`echo $LINE | awk '{print $2}'`

        if [[ $NAME == "" ]] 
        then  
            continue; 
        fi

        echo ""
        echo "[$NAME]"
        echo "CMSSW.datasetpath=$DATASET"
        echo "USER.user_remote_dir=$PRODNAME/$NAME"

    done
fi

############################
# Auto-detect crab folders #
############################

if [[ $inputTasks == "false" ]]
then
    CRABFOLDERS=`ls -d */log/crab.log 2>&1 | tr '/' ' ' | awk '{print $1}'`
    TASKS=""
    for FOLDER in $CRABFOLDERS
    do
        # Only keep FOLDERS that are not in ".octopusIgnore"
        if [[ `cat .octopusIgnore 2>/dev/null | grep ^$FOLDER$` == "" ]]
        then
            TASKS="$TASKS $FOLDER"
        fi
    done
fi

#####################
# Updating if asked #
#####################

if [[ $update == "true" ]]
then
    for TASK in $TASKS
    do
        echo "  Checking status of $TASK ... "
        crab -status -c $TASK > $TASK/status.tmp 2>&1
    done
fi

##################
# Writing report #
##################

if [[ $statusReport == "true" ]]
then 
    rm -f report.tmp

    echo ", ----------------- - ------ - ----- - ----- - ---- - ------- - ------- ," >> report.tmp
    echo "|        Task       | Submit |  Run  | Error |  OK  |  Clear  |  Total  |" >> report.tmp
    echo "- ----------------- - ------ - ----- - ----- - ---- - ------- - ------- -" >> report.tmp

    ALL_SUBMITTED=0
    ALL_RUNNING=0
    ALL_ERROR=0
    ALL_OK=0
    ALL_CLEAR=0
    ALL_TOTAL=0

    for TASK in $TASKS
    do
        cat $TASK/status.tmp | grep -E "^[0-9]" > .joblist.tmp

        SUBMITTED=`cat .joblist.tmp                              | grep "Submitted\|Scheduled" | wc -l`
        RUNNING=`  cat .joblist.tmp                              | grep "Running"   | wc -l`
        ERROR=`    cat .joblist.tmp | awk '{if (($3 == "Aborted") || ($5 != 0) || ($6 != 0)) print}' | grep -v "Submitted\|Scheduled\|Running" | wc -l`
        OK=`       cat .joblist.tmp | awk '{if (($5 == 0) && ($6 == 0)) print}' | grep "Done"      | wc -l`
        CLEAR=`    cat .joblist.tmp | awk '{if (($5 == 0) && ($6 == 0)) print}' | grep "Retrieved" | wc -l`
        TOTAL=`    cat .joblist.tmp | wc -l`

        if [[ $ignoreClear == "true" ]]
        then
            if [[ $CLEAR == $TOTAL ]]
            then
                echo "Adding $TASK to .octopusIgnore"
                echo $TASK >> .octopusIgnore
                continue;
            fi
        fi


        echo "| $TASK | $SUBMITTED | $RUNNING | $ERROR | $OK | $CLEAR | $TOTAL |" >> report.tmp

        ALL_SUBMITTED=`echo $ALL_SUBMITTED + $SUBMITTED | bc`
        ALL_RUNNING=`echo $ALL_RUNNING + $RUNNING | bc`
        ALL_ERROR=`echo $ALL_ERROR + $ERROR | bc`
        ALL_OK=`echo $ALL_OK + $OK | bc`
        ALL_CLEAR=`echo $ALL_CLEAR + $CLEAR | bc`
        ALL_TOTAL=`echo $ALL_TOTAL + $TOTAL | bc`
    done

    rm .joblist.tmp

    # Adding total line

    echo "- ----------------- - ------ - ----- - ----- - ---- - ------- - ------- -" >> report.tmp

    echo "| All | $ALL_SUBMITTED | $ALL_RUNNING | $ALL_ERROR | $ALL_OK | $ALL_CLEAR | $ALL_TOTAL |" >> report.tmp

    ALL_SUBMITTED=`echo $ALL_SUBMITTED "*" 100 / $ALL_TOTAL | bc`
    ALL_RUNNING=`echo $ALL_RUNNING "*" 100 / $ALL_TOTAL | bc`
    ALL_ERROR=`echo $ALL_ERROR "*" 100 / $ALL_TOTAL | bc`
    ALL_OK=`echo $ALL_OK "*" 100 / $ALL_TOTAL | bc`
    ALL_CLEAR=`echo $ALL_CLEAR "*" 100 / $ALL_TOTAL | bc`
    ALL_TOTAL=`echo $ALL_TOTAL "*" 100 / $ALL_TOTAL | bc`

    echo "| All(percent) | ${ALL_SUBMITTED}% | ${ALL_RUNNING}% | ${ALL_ERROR}% | ${ALL_OK}% | ${ALL_CLEAR}% | ${ALL_TOTAL}% |" >> report.tmp

    echo "- ----------------- - ------ - ----- - ----- - ---- - ------- - ------- -" >> report.tmp

    cat report.tmp | column -t

    rm report.tmp
fi

########################
# Writing error report #
########################

if [[ $errorReport == "true" ]]
then

    echo " Writing errors report ... (see https://twiki.cern.ch/twiki/bin/view/CMSPublic/JobExitCodes) "
    echo ", ----------------- - ------ " >> report.tmp

    for TASK in $TASKS
    do
        cat $TASK/status.tmp | grep -E "^[0-9]" | awk '{if (($5 != 0) || ($6 != 0)) print}' | grep -v "Submitted\|Scheduled\|Running\|Aborted" | awk '{print $6}' | sort -n | uniq -c > $TASK/errors.tmp
        nAborted=`cat $TASK/status.tmp | grep -E "^[0-9]" | awk '{if (($3 == "Aborted") || ($5 != 0) || ($6 != 0)) print}' | grep -v "Submitted\|Scheduled\|Running" | grep "Aborted" | wc -l`
        if [[ $nAborted != 0 ]]
        then 
            echo "$nAborted Aborted" >> $TASK/errors.tmp
        fi

        if [[ `cat $TASK/errors.tmp | wc -l` != 0 ]]
        then
            echo "| $TASK |" `cat $TASK/errors.tmp | awk '{print $2 " (x" $1 ")"}'` >> report.tmp
        fi
        rm $TASK/errors.tmp
    done
    echo ", ----------------- - ------ " >> report.tmp
    cat report.tmp | column -t
    rm report.tmp

fi

##################
# Resubmit tasks #
##################

if [[ $resubmit == "true" ]]
then
    for TASK in $TASKS
    do
        cat $TASK/status.tmp | grep -E "^[0-9]" | awk '{if (($3 == "Aborted") || ($5 != 0) || ($6 != 0)) print}' | grep -v "Submitted\|Scheduled\|Running" > resubmitList.tmp
        if [[ `cat resubmitList.tmp | wc -l` == 0 ]]
        then 
            echo No job to resubmit for $TASK
        else
            while [[ `cat resubmitList.tmp 2>/dev/null | wc -l` -gt 0 ]];
            do
                NRESUBMIT=`cat resubmitList.tmp | head -n500 | wc -l`
                echo Resubmitting $NRESUBMIT jobs for $TASK ...
                LIST=`cat resubmitList.tmp | head -n500 | awk '{print $1}' | tr '\n' ',' | sed 's/,$//g'`
                crab -forceResubmit $LIST -c $TASK > log.tmp
                cat log.tmp | grep "submitted" | tail -n1
                rm -f log.tmp
                cat resubmitList.tmp | tail -n +501 > resubmitList.tmp2
                mv resubmitList.tmp2 resubmitList.tmp
            done
        fi 
    done
    rm -f resubmitList.tmp
fi
