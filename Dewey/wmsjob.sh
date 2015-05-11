#!/bin/sh

START_TIME=`date` 
echo "============================" 
echo "       Beginning job        "
echo "                            "
echo "Start time : $START_TIME    "
echo "Hostname   : $HOSTNAME      "
echo "============================" 

lsb_release -a

OUTPUT_DIRECTORY="/dpm/in2p3.fr/home/cms/phedex/store/user/aaubin/testWMS/"
CMSSW_VERSION="5_3_11"

mkdir WMSsandbox
cd WMSsandbox

echo "> Setting up environment"
echo "(" `date` ")"
export LD_PRELOAD=/usr/lib64/libglobus_gssapi_gsi.so.4
export SCRAM_ARCH=slc6_amd64_gcc472
source /cvmfs/cms.cern.ch/cmsset_default.sh
cmsrel CMSSW_$CMSSW_VERSION
cd CMSSW_$CMSSW_VERSION/src
cmsenv
cd ../..

echo "> Starting task"
echo "(" `date` ")"
cmsRun prod_GENtoRECO.py fileItr=${jidx}

echo "> Copying output"
echo "(" `date` ")"
srmcp -overwrite_mode=ALWAYS -retry_num 4 -retry_timeout 30000 file:///${cdir}/RECO.root srm://sbgse1.in2p3.fr:8446${OUTPUT_DIRECTORY}prod_S1_mres${BENCHMARK}p0_${jidx}.root
if [ $? -ne 0 ]; then
    echo "retrying srmcp"
    srmcp -overwrite_mode=ALWAYS -retry_num 4 -retry_timeout 30000 file:///${cdir}/RECO.root srm://sbgse1.in2p3.fr:8446${OUTPUT_DIRECTORY}prod_S1_mres${BENCHMARK}p0_${jidx}.root
fi

echo "> Cleaning environment"
cd ${WDIR}
rm -rf ${sdir}

END_TIME=`date`
DURATION=$(())
echo "============================" 
echo "       Job ending           "
echo "                            "
echo "End time : $END_TIME        "
echo "============================" 
