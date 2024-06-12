#!/bin/bash
#SBATCH --account=def-jbpoline
#SBATCH --job-name=viprs_data
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8G
#SBATCH --array=0-229
#SBATCH --output=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/logs/data-extraction_%A_%a.log

# run 1 job per overlay, looping over all subjects in the overlay
SAMPLE_LIST=($(</lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/tractoflow_overlays.txt))
OVERLAY=${SAMPLE_LIST[${SLURM_ARRAY_TASK_ID}]}

# build the data paths
PROJDIR=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp
SCRATCH=/scratch/bcmcpher/ohbm

# the container to use
CONTAINER=$PROJDIR/container/fmriprep_20.2.7.sif

# the output paths for the data
OUTPATH=$PROJDIR/data/ohbm

# load the container
module load apptainer

# run the extraction
apptainer exec -B $PROJDIR \
	       -B $SCRATCH \
               --overlay $OVERLAY \
	       $CONTAINER $PROJDIR/bin/loop-align-t1-to-mni.sh
