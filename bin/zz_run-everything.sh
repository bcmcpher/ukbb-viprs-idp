#!/bin/bash
#SBATCH --account=def-jbpoline
#SBATCH --job-name=viprs_all
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32GB
#SBATCH --array=0-9
#SBATCH --output=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/logs/junk-logs_%A_%a.log

# # max array: 3935

# parse array index to ID. Created with: printf '%s\n' {0001..3935} > $PROJDIR/bin/idps_to_run.txt
SAMPLE_LIST=($(</lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/idps_to_run.txt))
IDP=${SAMPLE_LIST[${SLURM_ARRAY_TASK_ID}]}

# load the environment modules
module load apptainer
module load scipy-stack

# environment paths
PROJDIR=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp

# path to the container
APPTAIN=$PROJDIR/container/viprs-v0.1.0.sif

# overhead paths
LOGSDIR=$PROJDIR/bin/logs
DATADIR=$PROJDIR/data
TMPDIR=/scratch/bcmcpher/viprs

# change these for evaluation / subsets
RUN="ukbb-full"
KEEPID=$DATADIR/keep_files/ukbb_qc_variants.keep

# input files I need for fitting / scoring
FITGWAS=$PROJDIR/data/idps-fixed
LD_DATA=$PROJDIR/data/ld

# path to fits / outputs
JOBSDIR=$PROJDIR/data/viprs-full/$IDP
mkdir -p $JOBSDIR

# the fit (1) path and output file
FITSDIR=$JOBSDIR/$IDP
FITSOUT=${FITSDIR}.fit

# the scoring (2) path and output file
SCORES=$JOBSDIR/${IDP}_${RUN}_score
SCORED=${SCORES}.prs

# the evaluation input file
EVALS=$JOBSDIR/${IDP}_${RUN}_evaluate.tsv

# create the evaluation pheno file
python $PROJDIR/bin/copy-pheno-to-file.py $IDP $EVALS

# the results (3) of the evaluated scores
EOUTS=$JOBSDIR/${IDP}_${RUN}_result

# log redirect w/ useful name?
exec &> $LOGSDIR/viprs_all_${IDP}.log

echo "Fitting VIPRS on IDP: $IDP"

echo " -- 1) Fitting VIPRS..."
apptainer exec -B $PROJDIR -B $TMPDIR $APPTAIN \
	  viprs_fit --sumstats $FITGWAS/${IDP}-fixed.txt --ld-panel $LD_DATA --output-dir $FITSDIR --sumstats-format "magenpy"

echo " -- 2) Scoring VIPRS..."
apptainer exec -B $PROJDIR -B $TMPDIR $APPTAIN \
	  viprs_score --fit-files $FITSOUT --bfile "$DATADIR/bed/*.bed" --output-file $SCORES --temp-dir $TMPDIR --keep $KEEPID

echo " -- 3) Evaluating VIPRS..."
apptainer exec -B $PROJDIR -B $TMPDIR $APPTAIN \
	  viprs_evaluate --prs-file $SCORED --phenotype-file $EVALS --phenotype-likelihood gaussian --output-file $EOUTS

echo "Done fitting, scoring, and evaluting ${IDP} baseline."
