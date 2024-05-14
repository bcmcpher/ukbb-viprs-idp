#!/bin/bash
#SBATCH --account=def-jbpoline
#SBATCH --job-name=viprs_all
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8GB
#SBATCH --array=0-999
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

# change these for evaluation / subsets
RUN="ukbb-qc"
KEEPID=$DATADIR/keep_files/ukbb_qc_observations.keep
SNPSID=$DATADIR/keep_files/ukbb_qc_variants_hm3.keep

# input files I need for fitting / scoring
FITGWAS=$PROJDIR/data/idps-fixed
FGWAS=$FITGWAS/${IDP}-fixed.txt
PHENODT=$PROJDIR/data/idps_${RUN}
LD_DATA=$PROJDIR/data/ld-new/float32

# path to fits / outputs
JOBSDIR=$PROJDIR/data/viprs_$RUN/$IDP
mkdir -p $JOBSDIR

# the fit (1) path and output file
FITSDIR=$JOBSDIR
FITSOUT=$FITSDIR/VIPRS_EM.fit.gz

# the scoring (2) path and output file
SCORES=$JOBSDIR/VIPRS_SCORE
SCORED=${SCORES}.prs

# the evaluation input file
EVALS=$PHENODT/${IDP}_${RUN}_baseline-eval.tsv
FVALS=$PHENODT/${IDP}_${RUN}_followup-eval.tsv
EDIFF=$PHENODT/${IDP}_${RUN}_difference.tsv
ERATO=$PHENODT/${IDP}_${RUN}_ratio.tsv

# the results (3) of the evaluated scores
ENOUT=$JOBSDIR/${IDP}_${RUN}_baseline
FNOUT=$JOBSDIR/${IDP}_${RUN}_followup
EDOUT=$JOBSDIR/${IDP}_${RUN}_difference
EROUT=$JOBSDIR/${IDP}_${RUN}_ratio

# log redirect w/ useful name
exec &> $LOGSDIR/viprs_all_${IDP}.log

echo "Fitting VIPRS on IDP: $IDP"

echo " -- 1) Fitting VIPRS..."
if [ -f $FITGWAS/${IDP}-fixed.txt ]; then
   apptainer exec -B $PROJDIR $APPTAINER \
			 viprs_fit --sumstats $FGWAS --ld-panel $LD_DATA --output-dir $FITSDIR --sumstats-format magenpy --threads 4
fi

echo " -- 2) Scoring VIPRS..."
if [ -f $FITSOUT ]; then
	apptainer exec -B $PROJDIR $APPTAINER \
			  viprs_score --fit-files $FITSOUT --bfile "$DATADIR/bed/*.bed" --output-file $SCORES --temp-dir $JOBSDIR --keep $KEEPID --extract $SNPSID --backend plink --threads 4
fi

echo " -- 3) Evaluating VIPRS..."
echo " -- -- a) Evaluating full ses-2 sample..."
if [ -f $EVALS ]; then
	apptainer exec -B $PROJDIR $APPTAINER \
			  viprs_evaluate --prs-file $SCORED --phenotype-file $EVALS --phenotype-likelihood gaussian --output-file $ENOUT
fi

echo " -- -- b) Evaluating full ses-3 sample..."
if [ -f $FVALS ]; then
	apptainer exec -B $PROJDIR $APPTAINER \
			  viprs_evaluate --prs-file $SCORED --phenotype-file $FVALS --phenotype-likelihood gaussian --output-file $FNOUT
fi

echo " -- -- c) Evaluating sample difference..."
if [ -f $EDIFF ]; then
	apptainer exec -B $PROJDIR $APPTAINER \
			  viprs_evaluate --prs-file $SCORED --phenotype-file $EDIFF --phenotype-likelihood gaussian --output-file $EDOUT
fi

echo " -- -- d) Evaluating sample ratio..."
if [ -f $ERATO ]; then
	apptainer exec -B $PROJDIR $APPTAINER \
			  viprs_evaluate --prs-file $SCORED --phenotype-file $ERATO --phenotype-likelihood gaussian --output-file $EROUT
fi

echo "Done fitting, scoring, and evaluting ${IDP}."
