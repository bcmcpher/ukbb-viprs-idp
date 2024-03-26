#!/bin/bash

# build paths to data
UKBBDIR=/lustre03/project/6008063/neurohub/ukbb/new/Tabular
PROJDIR=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp
CCA_DIR=$PROJDIR/bin/ukbb-cca/scripts
DATADIR=$PROJDIR/data

# turn on venv for data handling
source $PROJDIR/bin/venv-ukbb-parse

# build UDIs for parsing inputs w/ Michelle's scripts
echo 'Create UKBB UDIs...'
python $CCA_DIR/process_UDIs.py \
	--fpath-raw $UKBBDIR/current.csv \
	--fpath-udis $DATADIR/ukbb-udis.txt

# try to just select the IDPs we want to use for time 1
echo 'Create UKBB ses-02 IDP test..'
python $CCA_DIR/select_mri_subjects.py \
	--fpath-raw $UKBBDIR/current.csv \
	--fpath-out $DATADIR/ukbb_idp_ses-02_test.csv \
	--fpath-udis $DATADIR/ukbb-udis.txt \
	--dpath-schema $PROJDIR/bin/ukbb-cca/data/schema \
	--add-instance 2

# and time 2
echo 'Create UKBB ses-03 IDP test...'
python $CCA_DIR/select_mri_subjects.py \
	--fpath-raw $UKBBDIR/current.csv \
	--fpath-out $DATADIR/ukbb_idp_ses-03_test.csv \
	--fpath-udis $DATADIR/ukbb-udis.txt \
	--dpath-schema $PROJDIR/bin/ukbb-cca/data/schema \
	--add-instance 3

