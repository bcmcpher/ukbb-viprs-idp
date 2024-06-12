#!/bin/bash

module load apptainer

PROJDIR=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp
SCRATCH=/scratch/bcmcpher/ohbm
OUTPATH=$PROJDIR/data/ohbm

CONTAINER=$PROJDIR/container/fmriprep_20.2.7.sif

#OVERLAY=/lustre03/project/6008063/neurohub/UKB/Derived/tractoflow_out/tractoflow_1050.squashfs
OVERLAY=/lustre03/project/6008063/neurohub/UKB/Derived/tractoflow_creating/tractoflow_ses-3_results_05.squashfs

apptainer exec -B $PROJDIR \
	       -B $SCRATCH \
	       --overlay $OVERLAY \
	       $CONTAINER $PROJDIR/bin/loop-align-t1-to-mni.sh
