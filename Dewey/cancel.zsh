#!/bin/env zsh

jname="jobs.txt"

fid="${jname}"

cat ${fid} | while read line
do
jid=$(echo $line | awk '{print $2}')
echo $jid
glite-wms-job-cancel --noint ${jid}
done

