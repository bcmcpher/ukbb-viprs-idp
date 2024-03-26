#!/bin/bash

echo "Loading dependency..."

module load plink

# hard code parameters
MIN_MAF=0.001
MAX_MAF=0.999
MIN_MAC=5
MIND=0.05
GENO=0.05
HWE_CUTOFF=1e-10
HARDCALL_THRES=0.1

# The path to the UKBB genotype data: (See data_preparation/ukbb_qc_job.sh for how this path is used)
# UKBB_GENOTYPE_DIR="/lustre03/project/6004777/projects/uk_biobank/imputed_data/full_UKBB/v3_bgen12"
UKBB_GENOTYPE_DIR="/lustre03/project/6008063/neurohub/ukbb/genetics/new_imputation/UKB_imputation_from_genotype"

# The path to the UKBB phenotype data: (See data_preparation/prepare_real_phenotypes.py for how this path is used)
UKBB_PHENOTYPE_DIR="/lustre03/project/6004777/projects/uk_biobank/raw"

# output
OUTPUT=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/bed

echo "Set run variables..."

ind_keep_file="/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/keep_files/ukbb_qc_variants.keep"
snp_keep="/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/keep_files/ukbb_qc_variants.keep"

echo "Attempting to create bed file..."

plink2 --bgen "$UKBB_GENOTYPE_DIR/ukb22828_c1_b0_v3.bgen" ref-first \
	   --sample "$UKBB_GENOTYPE_DIR/ukb22828_c1_b0_v3.sample" \
	   --make-bed \
	   --allow-no-sex \
	   --hwe "$HWE_CUTOFF" \
	   --mind "$MIND" \
	   --geno "$GENO" \
	   --mac "$MIN_MAC" \
	   --maf "$MIN_MAF" \
	   --max-maf "$MAX_MAF" \
	   --snps-only \
	   --max-alleles 2 \
	   --hard-call-threshold "$HARDCALL_THRES" \
	  --keep "$ind_keep_file" \
	  --extract "$snp_keep" \
	   --out $OUTPUT/zz_test

echo "A test .bed file is hopefully created."
