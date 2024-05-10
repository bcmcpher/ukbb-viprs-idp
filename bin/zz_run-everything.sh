#!/bin/bash
#SBATCH --account=def-jbpoline
#SBATCH --job-name=viprs_all
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8GB
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
APPTAINER=$PROJDIR/container/viprs-v0.1.0.sif

# overhead paths
LOGSDIR=$PROJDIR/bin/logs
DATADIR=$PROJDIR/data
TMPDIR=/scratch/bcmcpher/viprs

# change these for evaluation / subsets
RUN="ukbb-qc"
KEEPID=$DATADIR/keep_files/ukbb_qc_observations.keep
SNPSID=$DATADIR/keep_files/ukbb_qc_variants_hm3.keep

# input files I need for fitting / scoring
FITGWAS=$PROJDIR/data/idps-fixed
PHENODT=$PROJDIR/data/idps_${RUN}
LD_DATA=$PROJDIR/data/ld-new/float32

# path to fits / outputs
JOBSDIR=$PROJDIR/data/viprs_$RUN/$IDP
mkdir -p $JOBSDIR

# the fit (1) path and output file
FITSDIR=$JOBSDIR
FITSOUT=VIPRS_EM.fit.gz

# the scoring (2) path and output file
SCORES=$JOBSDIR/VIPRS_${IDP}_${RUN}_SCORE
# SCORES=$JOBSDIR
SCORED=${SCORES}  # does this need an extension? change w/ --compress?

# the evaluation input file
EVALS=$JOBSDIR/${IDP}_${RUN}_baseline-eval.tsv
FVALS=$JOBSDIR/${IDP}_${RUN}_followup-eval.tsv
EDIFF=$PHENODT/${IDP}_${RUN}_difference.tsv
ERATO=$PHENODT/${IDP}_${RUN}_ratio.tsv

# the results (3) of the evaluated scores
ENOUT=$JOBSDIR/${IDP}_${RUN}_baseline
FNOUT=$JOBSDIR/${IDP}_${RUN}_followup
EDOUT=$JOBSDIR/${IDP}_${RUN}_difference
EROUT=$PHENODT/${IDP}_${RUN}_ratio

# log redirect w/ useful name
exec &> $LOGSDIR/viprs_all_${IDP}.log

echo "Fitting VIPRS on IDP: $IDP"

echo " -- 1) Fitting VIPRS..."
apptainer exec -B $PROJDIR -B $TMPDIR $APPTAINER \
	  viprs_fit --sumstats $FITGWAS/${IDP}-fixed.txt --ld-panel $LD_DATA --output-dir $FITSDIR --sumstats-format magenpy --threads 4  # v0.1.0

echo " -- 2) Scoring VIPRS..."
apptainer exec -B $PROJDIR -B $TMPDIR $APPTAINER \
	  viprs_score --fit-files $FITSOUT --bfile "$DATADIR/bed/*.bed" --output-file $SCORES --temp-dir $TMPDIR --keep $KEEPID --extract $SNPSID --backend plink --threads 4  # v0.1.0

echo " -- 3) Evaluating VIPRS..."
echo " -- -- a) Estimating full sample..."
if [ -f $EVALS ]; then
	apptainer exec -B $PROJDIR -B $TMPDIR $APPTAINER \
			  viprs_evaluate --prs-file $SCORED --phenotype-file $EVALS --phenotype-likelihood gaussian --output-file $ENOUT  # v0.1.0
fi

echo " -- -- b) Estimating full sample..."
if [ -f $EVALS ]; then
	apptainer exec -B $PROJDIR -B $TMPDIR $APPTAINER \
			  viprs_evaluate --prs-file $SCORED --phenotype-file $FVALS --phenotype-likelihood gaussian --output-file $FNOUT  # v0.1.0
fi

echo " -- -- c) Estimating sample difference..."
if [ -f $EDIFF ]; then
	apptainer exec -B $PROJDIR -B $TMPDIR $APPTAINER \
			  viprs_evaluate --prs-file $SCORED --phenotype-file $EDIFF --phenotype-likelihood gaussian --output-file $EDOUT  # v0.1.0
fi

echo " -- -- d) Estimating sample ratio..."
if [ -f $ERATO ]; then
	apptainer exec -B $PROJDIR -B $TMPDIR $APPTAIER \
			  viprs_evaluate --prs-file $SCORED --phenotype-file $ERATO --phenotype-likelihood gaussian --output-file $EROUT  # v0.1.0
fi

echo "Done fitting, scoring, and evaluting ${IDP}."
