#!/bin/bash

usern="mbuttign"

####################################################################
#                                                                  #
#  Author : Michael Buttignol  @ IPHC Strasbourg, 2014             #
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
#  see "dewey -h"                                                  #
#                                                                  #
####################################################################

###################
# Parsing options #
###################

printHelp="false"
update="false"
errorReport="false"
resubmit="false"
inputColls='false'
statusReport="false"
ignoreClear="false"

OPTIONS=`getopt -o "hC:SUERI" --long "help collections: status update errors resubmit ignoreClear" -n dewey -- "$@"`
eval set -- "$OPTIONS"
while true
do
    case "$1" in
        -h | -H | --help)       printHelp="true";      shift ;;
        -C | --collections)     inputColls="true";     COLLECTIONS="$2"; shift 2 ;;
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
  Dewey
 ---------
 Tool to monitor and manage multiple crab tasks from command-line.                                                 

 By default, the list of task to consider is detected automatically from the crab folders in the current directory.
 You can also ignore some tasks by listing them in a file named .deweyIgnore.                                  
 NB: if -U option is not specified, the job status are not automatically updated since the last dewey -U.        

 Usage: dewey <[options]>
 Options:
        -H  --help                           Print this help, duh.
        -C  --collections  \"Task1 Task2\"   Specify the list of collections to monitor instead of automatic detection.
        -S  --status                         Show a status report of the tasks.
        -U  --update                         Update the status (crab -status) for each task before the status report.
        -E  --errors                         Show a summary of the error/crash reasons.
        -R  --resubmit                       Ask crab to resubmit each task with a faulty status.
        -I  --ignoreClear                    With option -S, add tasks with 100% clear completion to the .octopusIgnore
    "
    exit
fi

############################
# Auto-detect collections  #
############################

if [[ $inputColls == "false" ]]
then
    JobFile="jobs.txt"
    COLL=""
    COLLS=""
    while read line
    do    
        # Make the CollName and the CollURL be an unique entry in "COLLS"
        COLL=`echo $line | tr ' ' '&'`

        COLLS="$COLLS $COLL"
    done < $JobFile
fi


##################
# Writing report #
##################

if [[ $statusReport == "true" ]]
then

    echo ", -------------------- - ------ - ----- - ----- - ---- - ------- ," >  report.tmp
    echo "|        Collection    | Submit |  Run  | Error |  OK  |  Total  |" >> report.tmp
    echo "- -------------------- - ------ - ----- - ----- - ---- - ------- -" >> report.tmp

    ALL_SUBMITTED=0
    ALL_RUNNING=0
    ALL_ERROR=0
    ALL_OK=0
    ALL_TOTAL=0

    for COLL in $COLLS
    do
        # Get the name of the collection
        COLL_NAME=`echo ${COLL} | tr '&' ' ' | awk '{print $1}'`

        # Get the URL of the collection
        COLL_URL=`echo ${COLL} | tr '&' ' ' | awk '{print $2}'`

        # Get the status and the JobId (URL) of all the SubJobs in the collection "COLL"
        glite-wms-job-status ${COLL_URL} > ${COLL_NAME}/.joblist.tmp

        # Remove the 8 first and last 2 generic lines of the global JOB status report
        sed '1,8d' ${COLL_NAME}/.joblist.tmp         > ${COLL_NAME}/.joblist_tmp.tmp
        sed '$d'   ${COLL_NAME}/.joblist_tmp.tmp     > ${COLL_NAME}/.joblist.tmp
        sed '$d'   ${COLL_NAME}/.joblist.tmp         > ${COLL_NAME}/.joblist_tmp.tmp

        # Have both the JobId and its status on the same line
        sed -e :a -e '$!N;s/\n    Current/ /;ta' -e 'P;D' ${COLL_NAME}/.joblist_tmp.tmp > ${COLL_NAME}/.joblist.tmp

        rm -f ${COLL_NAME}/.jobstatus
        if [[ -z `echo ${COLL_NAME} | grep "reSubmit"` ]]; then echo "Getting status of collection: "${COLL_NAME}...; fi
     
        # Remove from the 'Done/Cleared' status the jobs where not all events were processed but no error occurs
        while read line 
        do
                URLofDoneStatus=`   echo ${line} | grep "Done"    | awk '{print $7}'`
                URLofClearedStatus=`echo ${line} | grep "Cleared" | awk '{print $7}'`

                # Get the URL of the job
                URLofJob=`echo ${line} | awk '{print $7}'`

                # Display more info about the job tagged by "URLofJob"
                glite-wms-job-status -v 3 ${URLofJob} > ${COLL_NAME}/.currentJobFullStatus.tmp
                # Get the Node number of the current job
                NODEofCurrentJob=`grep "NodeName" ${COLL_NAME}/.currentJobFullStatus.tmp | head -n 1 | awk '{print $3}' | tr '_' ' '  | awk '{print $3}'`

                # If the job is in 'Done' status then check if there is any error in the stderr
                if [[ -n "$URLofDoneStatus" ]]
                then
                    TagofURL=`echo ${URLofDoneStatus} | tr '/' ' ' | awk '{print $3}'`
                        
                    # Get the std::output of the job
                    mkdir -p ${COLL_NAME}/outputs/
                    rm -rf ${COLL_NAME}/outputs/${usern}_${TagofURL}
                    glite-wms-job-output --dir ${COLL_NAME}/outputs/ ${URLofDoneStatus} > ${COLL_NAME}/.output.tmp
                    ErrorInOutput=`grep "Fatal Exception" ${COLL_NAME}/outputs/${usern}_${TagofURL}/stderr.err`

                    # If there is an error, change the status from Done to Aborted
                    if [[ -n "$ErrorInOutput" ]]
                    then
                        newline=` echo $line | sed -e "s/Done(Success)/Aborted/"`
                        echo ${newline} ${NODEofCurrentJob} >> ${COLL_NAME}/.jobstatus
                    else 
                        echo ${line} ${NODEofCurrentJob} >> ${COLL_NAME}/.jobstatus
                    fi
                # If the job is in 'Cleared' status then check if there is any error in the stderr
                elif [[ -n "$URLofClearedStatus" ]]
                then
                     TagofURL=`echo ${URLofClearedStatus} | tr '/' ' ' | awk '{print $3}'`
                    # Directly check in the stderr if a problem occurs
                    ErrorInOutput=`grep "Fatal Exception" ${COLL_NAME}/outputs/${usern}_${TagofURL}/stderr.err`
                    
                    if [[ -n "$ErrorInOutput" ]]
                    then
                        newline=` echo $line | sed -e "s/Cleared/Aborted/"`
                        echo ${newline} ${NODEofCurrentJob} >> ${COLL_NAME}/.jobstatus
                    else 
                        echo ${line} ${NODEofCurrentJob} >> ${COLL_NAME}/.jobstatus
                    fi
                else echo ${line} ${NODEofCurrentJob} >> ${COLL_NAME}/.jobstatus
                fi
        done < ${COLL_NAME}/.joblist.tmp
        rm -f ${COLL_NAME}/.joblist_tmp.tmp
    done


    # Modify the .jobstatus of all main collections in updating the status of resubmitted jobs
    for COLL in $COLLS
    do
        # Get the name of the collection
        COLL_NAME=`echo ${COLL} | tr '&' ' ' | awk '{print $1}'`
        
        if [[ -d ${COLL_NAME}_reSubmit_0 ]]
        then
               # Test the existence of a previous "resubmit" directory
               i=0
               while [[ -d ${COLL_NAME}_reSubmit_${i} ]]
               do
                   while read line
                   do
                           NodeOfResubmittedJob=`echo ${line} | awk '{print $10}'`
                           # Link the job with the initial one 
                           MatchInitialStatusLine=`cat ${COLL_NAME}/.jobstatus | awk -v var=${NodeOfResubmittedJob} '{if ($10 == var) print}'`
                           if [[ -n ${MatchInitialStatusLine} ]]
                           then
                                   # Update the .jobstatus with the status of the resubmitted jobs (most recent)
                                   sed -e "s|${MatchInitialStatusLine}|${line}|g" ${COLL_NAME}/.jobstatus > ${COLL_NAME}/.jobstatus.tmp
                                   cp ${COLL_NAME}/.jobstatus.tmp ${COLL_NAME}/.jobstatus
                           fi
                   done < ${COLL_NAME}_reSubmit_${i}/.jobstatus
                   i=$(( ${i} + 1))
               done
        fi

        # Do not display the status of resubmitted Collections
        if [[ -z `echo ${COLL_NAME} | grep "reSubmit"` ]]
        then 
              
              WAITING=`  cat ${COLL_NAME}/.jobstatus | grep "Waiting"                    | wc -l`
              SUBMITTED=`cat ${COLL_NAME}/.jobstatus | grep "Submitted\|Scheduled"       | wc -l`
              RUNNING=`  cat ${COLL_NAME}/.jobstatus | grep "Running"                    | wc -l`
              ERROR=`    cat ${COLL_NAME}/.jobstatus | grep "Cancelled\|Aborted"         | wc -l`
              OK=`       cat ${COLL_NAME}/.jobstatus | grep "Done\|Cleared"              | wc -l`
              TOTAL=`    cat ${COLL_NAME}/.jobstatus                                     | wc -l`
      
              echo "| $COLL_NAME | $SUBMITTED | $RUNNING | $ERROR | $OK | $TOTAL |" >> report.tmp
      
              ALL_SUBMITTED=` echo $ALL_SUBMITTED + $SUBMITTED | bc`
              ALL_RUNNING=`   echo $ALL_RUNNING + $RUNNING     | bc`
              ALL_ERROR=`     echo $ALL_ERROR + $ERROR         | bc`
              ALL_OK=`        echo $ALL_OK + $OK               | bc`
              ALL_TOTAL=`     echo $ALL_TOTAL + $TOTAL         | bc`
        fi
    done

    # Adding total line

    echo "- -------------------- - ------ - ----- - ----- - ---- -  ------- -" >> report.tmp

    echo "| All | $ALL_SUBMITTED | $ALL_RUNNING | $ALL_ERROR | $ALL_OK | $ALL_TOTAL |" >> report.tmp

    ALL_SUBMITTED=`  echo $ALL_SUBMITTED "*" 100 / $ALL_TOTAL | bc`
    ALL_RUNNING=`    echo $ALL_RUNNING   "*" 100 / $ALL_TOTAL | bc`
    ALL_ERROR=`      echo $ALL_ERROR     "*" 100 / $ALL_TOTAL | bc`
    ALL_OK=`         echo $ALL_OK        "*" 100 / $ALL_TOTAL | bc`
    ALL_TOTAL=`      echo $ALL_TOTAL     "*" 100 / $ALL_TOTAL | bc`

    echo "| All(percent) | ${ALL_SUBMITTED}% | ${ALL_RUNNING}% | ${ALL_ERROR}% | ${ALL_OK}% | ${ALL_TOTAL}% |" >> report.tmp

    echo "- -------------------- - ------ - ----- - ----- - ---- -  ------- -" >> report.tmp

    cat report.tmp | column -t

    rm report.tmp
fi

########################
# Writing error report #
########################

if [[ $errorReport == "true" ]]
then

    echo " Writing errors report ... (see https://www.ersa.edu.au/pbs_exitcodes) "
    echo " "
    echo " " > errors.tmp

    echo ", --------------------- - ------ - --------------------------------------------------------- ," >> errors.tmp
    echo "|    Collection         | JobId  |                          Error                            |" >> errors.tmp
    echo "- --------------------- - ------ - --------------------------------------------------------- -" >> errors.tmp

    for COLL in $COLLS
    do
        # Get the name of the collection
        COLL_NAME=`echo ${COLL} | tr '&' ' ' | awk '{print $1}'`

        # Get the URL of the collection
        COLL_URL=`echo ${COLL} | tr '&' ' ' | awk '{print $2}'`

        cat ${COLL_NAME}/.jobstatus | grep "Aborted" > ${COLL_NAME}/.abortedList.tmp


        if [[ -z `echo ${COLL_NAME} | grep "reSubmit"` ]]
        then
             if [[ `cat ${COLL_NAME}/.abortedList.tmp | wc -l` == 0 ]]
             then
                 echo No aborted job for collection: ${COLL_NAME}
             else
                 echo Checking errors for collection: ${COLL_NAME}
     
                 while read line
                 do
                     URLtoCheckError=`echo $line | grep "Aborted" | awk '{print $7}'`
     
                     # If the variable is not empty then check the error
                     if [[ -n "$URLtoCheckError" ]]
                     then 
                         # Display more info about the job tagged by "URLtoCheckError"
                         glite-wms-job-status -v 3 ${URLtoCheckError} > ${COLL_NAME}/.abortedURL.tmp
     
                         # Look for the PBS_reason of the crash
                         PBSError=`grep "Failure reasons" ${COLL_NAME}/.abortedURL.tmp`
                         PBSErrorSubStr=`echo ${PBSError:34:54} | tr ' ' '_'`
     
                         # Look for the Node matching the URLtoCheckError
                         NODEofError=`grep "NodeName" ${COLL_NAME}/.abortedURL.tmp | head -n 1 | awk '{print $3}' | tr '_' ' '  | awk '{print $3}'`
     
                         echo "  | ${COLL_NAME} |  ${NODEofError} | ${PBSErrorSubStr} |" >> errors.tmp
                     fi
                 done < ${COLL_NAME}/.jobstatus
                 echo "- --------------------- - ------ - --------------------------------------------------------- -" >> errors.tmp
             fi
        fi
    done
    cat errors.tmp | column -t
    rm errors.tmp

fi

##################
# Resubmit jobs  #
##################

if [[ $resubmit == "true" ]]
then
    for COLL in $COLLS
    do
        # Get the name of the collection
        COLL_NAME=`echo ${COLL} | tr '&' ' ' | awk '{print $1}'`

        # Get the URL of the collection
        COLL_URL=`echo ${COLL} | tr '&' ' ' | awk '{print $2}'`

        cat ${COLL_NAME}/.jobstatus | grep "Cancelled\|Aborted" > ${COLL_NAME}/.resubmitList.tmp

        if [[ -z `echo ${COLL_NAME} | grep "reSubmit"` ]]
        then
             if [[ `cat ${COLL_NAME}/.resubmitList.tmp | wc -l` == 0 ]]
             then
                 echo No job to resubmit for collection: ${COLL_NAME}
             else
                 echo Resubmitting jobs for collection: ${COLL_NAME}
     
                 # Test the existence of a previous "resubmit" directory
                 i=0
                 while [[ -d ${COLL_NAME}_reSubmit_${i} ]]
                 do
                     i=$(( ${i} + 1))
                 done
     
                 # Create the right "resubmit" directory
                 mkdir ${COLL_NAME}_reSubmit_${i}
     
                 while read line
                 do
                     URLtoResubmit=`echo $line | grep "Cancelled\|Aborted" | awk '{print $7}'`
     
                     # if the variable is not empty then submit the task
                     if [[ -n "$URLtoResubmit" ]]
                     then 
                         # Display more info about the job tagged by "URLtoResubmit"
                         glite-wms-job-status -v 3 ${URLtoResubmit} > ${COLL_NAME}/.resubmitURL.tmp
     
                         # Stock the line which will be then changed by the new one in the .jobstatus
                         FormerLine=`cat ${COLL_NAME}/.resubmitList.tmp | grep ${URLtoResubmit}`
     
                         # Look for the Node matching the URLtoResubmit
                         NODEtoResubmit=`grep "NodeName" ${COLL_NAME}/.resubmitURL.tmp | head -n 1 | awk '{print $3}' | tr '_' ' '  | awk '{print $3}'`
                         echo "     Resubmitting JobId = "${NODEtoResubmit}...
     
                         cp ${COLL_NAME}/j_${NODEtoResubmit}.jdl ${COLL_NAME}_reSubmit_${i}/
                     fi
                     rm -f ${COLL_NAME}/.resubmitURL.tmp
                 done < ${COLL_NAME}/.resubmitList.tmp
        
             # Resubmit a new collection containing all the failed job
             URLofSubCollection=`glite-wms-job-submit -a --collection ${COLL_NAME}_reSubmit_${i} 2>&1 | grep "https://sbgwms1.in2p3.fr:9000"`
             echo "${COLL_NAME}_reSubmit_${i}   ${URLofSubCollection}" >> jobs.txt
             fi
        fi
    done
    rm -f ${COLL_NAME}/.resubmitList.tmp
fi

