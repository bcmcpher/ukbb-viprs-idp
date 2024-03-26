#!/bin/bash
#SBATCH --account=def-jbpoline
#SBATCH --job-name=run_viprs
#SBATCH --time=01:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8GB
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
SCRATCH=$PROJDIR/data/idps-fixed
LD_DATA=$PROJDIR/data/ld
FITSDIR=$PROJDIR/data/viprs-fits/$IDP
TMPDIR=/scratch/bcmcpher/viprs

# log redirect w/ useful name?
exec &> $LOGSDIR/viprs_fit_${IDP}.log

echo "Fitting VIPRS on IDP: $IDP"

# source python environment
# echo " -- Creating python virtual environment"
# #source $PROJDIR/bin/venv-viprs/bin/activate
# module load python/3.8
# virtualenv --no-download $SLURM_TMPDIR/env
# source $SLURM_TMPDIR/env/bin/activate
# pip install --no-index --upgrade pip

# pip install --no-index -r $PROJDIR/git/magenpy/requirements.txt
# pip install --no-index -r $PROJDIR/git/magenpy/requirements-optional.txt
# pip install --no-index magenpy

# pip install --no-index -r $PROJDIR/git/viprs/requirements.txt
# pip install --no-index -r $PROJDIR/git/viprs/requirements-optional.txt
# pip install --no-index viprs

#pip install --no-index -r $PROJDIR/bin/requirements.txt

module load apptainer
module load scipy-stack
module load plink

# just dump the data...
echo " -- Creating input..."
zcat $DATADIR/idps/$IDP.txt.gz > $SCRATCH/$IDP.txt

# run python to add sample size and fix variable names
python $PROJDIR/bin/fix-pheno-file.py $IDP

# # if zipped up fixed summary data exits
# if [ -e $SCRATCH/${IDP}-fixed.txt.gz ]; then

#     # unzip it to get fit
#     echo " -- Unpacking previously fixed data"
#     gunzip $SCRATCH/${IDP}-fixed.txt.gz

# else

#     echo " -- Creating fixed data"

#     # make a copy and unzip the raw phenofile to append correct sample size
#     #cp $DATADIR/idps/$IDP.txt.gz $SCRATCH

#     # because why would .gz files just work?
#     #gunzip $SCRATCH/$IDP.txt.gz || zcat $SCRATCH/$IDP.txt.gz > $SCRATCH/$IDP.txt
#     # { #try
#     #		gunzip $SCRATCH/$IDP.txt.gz &&
#     # } || { #catch
#     #		zcat $SCRATCH/$IDP.txt.gz > $SCRATCH/$IDP.txt
#     # }

#     # run python to add sample size and fix variable names
#     python $PROJDIR/bin/fix-pheno-file.py $IDP

#     # clean up $SCRATCH
#     #rm $SCRATCH/$IDP.txt

# fi

echo " -- Fitting VIPRS..."

# fit the model on the precomputed GWAS
# $SLURM_TMPDIR/env/bin/viprs_fit --sumstats $SCRATCH/${IDP}-fixed.txt \
#				--ld-panel $LD_DATA \
#				--output-file $FITSDIR \
#				--sumstats-format "magenpy"

apptainer exec -B $PROJDIR -B $TMPDIR \
	  $PROJDIR/container/viprs.sif \
	  viprs_fit --sumstats $SCRATCH/${IDP}-fixed.txt --ld-panel $LD_DATA --output-file $FITSDIR --sumstats-format "magenpy"

# # clean up weird intermediary scripting folders?
# if [ -d ./output ]; then
#     rmdir output
# fi

# if [ -d ./temp ]; then
#     rmdir temp
# fi

# (re)compress fixed file
#gzip $SCRATCH/${IDP}-fixed.txt

# use the fit to estimate the polygenic scores
# $PROJECT/bin/venv-viprs/bin/viprs_score -f $FIT --bed-files $BED --output-file $SCORE --temp-dir $TMPDIR --backend plink --compress
