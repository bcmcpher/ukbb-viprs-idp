#!/bin/bash
#SBATCH --account=def-jbpoline
#SBATCH --job-name=eval_viprs
#SBATCH --time=00:01:00
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8GB
#SBATCH --array=0-9
#SBATCH --output=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/logs/junk-logs_%A_%a.log

# # max array: 3935

# parse array index to ID. Created with: printf '%s\n' {0001..3935} > $PROJDIR/bin/idps_to_run.txt
SAMPLE_LIST=($(</lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/idps_to_run.txt))
IDP=${SAMPLE_LIST[${SLURM_ARRAY_TASK_ID}]}

# environment paths
PROJDIR=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp
LOGSDIR=$PROJDIR/bin/logs
DATADIR=$PROJDIR/data

# the participant batch for fitting
RUN="ukbb-full"
SCORES=$DATADIR/viprs-scores/$RUN/$IDP.prs.gz

# log redirect w/ useful name
exec &> $LOGSDIR/viprs_eval_${IDP}.log

# load environment variable
module load apptainer
module load scipy-stack

echo "Scoring VIPRS on IDP: $IDP"

# unzip the results so they can be loaded
gunzip $SCORES

# create the evaluation pheno file
python $PROJDIR/bin/copy-pheno-to-file.py $IDP

# run the evaluation
apptainer exec -B $PROJDIR -B $TMPDIR \
	  $PROJDIR/container/viprs-fixed.sif \
	  viprs_evaluate --prs-file $DATADIR/viprs-scores/$RUN/$IDP.prs \
	  --phenotype-file $DATADIR/viprs-evals/${IDP}-eval.tsv \
	  --phenotype-likelihood gaussian \
	  --output-file $DATADIR/viprs-evals/${IDP}-outs
