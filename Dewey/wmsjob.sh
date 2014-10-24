#!/bin/sh

export LFC_HOST=sbglfc1.in2p3.fr
BENCHMARK="1000p0_mchi800"
#BENCHMARK="1000p0_mchi100"
#BENCHMARK="500p0_mchi100"


echo "=====  Begin  =====" 
date
echo "The program is running on $HOSTNAME"
date
echo "=====  End  ====="

lsb_release -a

outdir="/dpm/in2p3.fr/home/cms/phedex/store/user/mbuttign/Prod_S1_RECO/prod_S1_mres${BENCHMARK}p0/"

jidx=${1}

WDIR=$(pwd)
sdir="genwd"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${WDIR}
export LD_PRELOAD=/usr/lib64/libglobus_gssapi_gsi.so.4

export SCRAM_ARCH=slc6_amd64_gcc472
source /cvmfs/cms.cern.ch/cmsset_default.sh

mkdir ${sdir}
cd ${sdir}
cmsrel CMSSW_5_3_11
cd CMSSW_5_3_11/src
cmsenv
cdir=$(pwd)

mv ${WDIR}/prod_GENtoRECO.py .
date
cmsRun prod_GENtoRECO.py fileItr=${jidx}
date

srmcp -overwrite_mode=ALWAYS -retry_num 4 -retry_timeout 30000 file:///${cdir}/RECO.root srm://sbgse1.in2p3.fr:8446${outdir}prod_S1_mres${BENCHMARK}p0_${jidx}.root
if [ $? -ne 0 ]; then
echo "retrying srmcp"
srmcp -overwrite_mode=ALWAYS -retry_num 4 -retry_timeout 30000 file:///${cdir}/RECO.root srm://sbgse1.in2p3.fr:8446${outdir}prod_S1_mres${BENCHMARK}p0_${jidx}.root
fi

cd ${WDIR}
rm -rf ${sdir}
