#!/bin/env zsh

usern="mbuttign"
COLL="Res1000Inv800"

if [[ -f jobs.txt ]]; then 
        CollNameAlreadyTaken=`cat jobs.txt | grep ${COLL}`
        if [[ -n ${CollNameAlreadyTaken} ]]; then
                echo "This Collection name is already taken, please choose another one" 
        else

                glite-wms-job-delegate-proxy -d ${usern}

                rm -rf ${COLL}
                mkdir ${COLL}

                for i in {1..100}
                do
                        cat j.jdl | sed "s%Arguments = \"wmsjob.sh%Arguments = \"wmsjob.sh ${i}%g" > ${COLL}/j_${i}.jdl
                done

                outp=$(glite-wms-job-submit -a --collection ${COLL} 2>&1 | grep "https://sbgwms1.in2p3.fr:9000")

                echo "${COLL}   $outp" >> jobs.txt
        fi
else 
        echo "Please first create an empty jobs.txt."
fi
