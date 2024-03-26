#!/bin/bash
#SBATCH --account=def-jbpoline
#SBATCH --job-name=score_viprs
#SBATCH --time=05:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32GB
#SBATCH --array=3000-3935
#SBATCH --output=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/logs/junk-logs_%A_%a.log

# # max array: 3935

# parse array index to ID. Created with: printf '%s\n' {0001..3935} > $PROJDIR/bin/idps_to_run.txt
SAMPLE_LIST=($(</lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/idps_to_run.txt))
IDP=${SAMPLE_LIST[${SLURM_ARRAY_TASK_ID}]}

# environment paths
PROJDIR=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp
LOGSDIR=$PROJDIR/bin/logs
DATADIR=$PROJDIR/data
FIT=$DATADIR/viprs-fits/$IDP.fit
TMPDIR=/scratch/bcmcpher/viprs

# the participant batch for fitting
RUN="ukbb-full"
SCORES=$DATADIR/viprs-scores/$RUN/$IDP
KEEPID=$DATADIR/keep_files/ukbb_qc_variants.keep

# log redirect w/ useful name?
exec &> $LOGSDIR/viprs_score_${IDP}.log

# load environment variable
module load apptainer

echo "Scoring VIPRS on IDP: $IDP"

apptainer exec -B $PROJDIR -B $TMPDIR \
	  $PROJDIR/container/viprs-fixed.sif \
	  viprs_score --fit-files $FIT --bed-files "$DATADIR/bed/*.bed" --output-file $SCORES \
	  --temp-dir $TMPDIR --keep $KEEPID --backend plink --compress
