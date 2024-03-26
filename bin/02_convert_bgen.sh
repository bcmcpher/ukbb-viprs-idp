#!/bin/bash
#SBATCH --account=def-jbpoline
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8GB
#SBATCH --time=08:00:00
#SBATCH --output=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/logs/convert_bgen_chr-%a_job-%a.log
#SBATCH --array=1-22

echo "Job started at: `date`"
echo "Job ID: $SLURM_JOBID"

# reassing --array index to chromosome name
CH=$SLURM_ARRAY_TASK_ID

#
# define parameters - taken from previous project
#

# Minimum/Maximum allele frequency and count:
MIN_MAF=0.001
MAX_MAF=0.999
MIN_MAC=5

# Missingness rate filters:
MIND=0.05  # Maximum missingness rate for individuals
GENO=0.05  # Maximum missingness rate for SNPs

# Hardy-Weinberg Equilibrium test cutoff:
HWE_CUTOFF=1e-10

# Hard call threshold:
HARDCALL_THRES=0.1

# The path to the viprs-paper home directory:
# Derived from the location of the config script. You may hardcode it here if you wish.
#VIPRS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# The path to the UKBB genotype data: (See data_preparation/ukbb_qc_job.sh for how this path is used)
#UKBB_GENOTYPE_DIR="/lustre03/project/6004777/projects/uk_biobank/imputed_data/full_UKBB/v3_bgen12"
UKBB_GENOTYPE_DIR="/lustre03/project/6008063/neurohub/ukbb/genetics/new_imputation/UKB_imputation_from_genotype"

# The path to the UKBB phenotype data: (See data_preparation/prepare_real_phenotypes.py for how this path is used)
#UKBB_PHENOTYPE_DIR="/lustre03/project/6004777/projects/uk_biobank/raw"

# The path to the 1000 Genomes genotype data: (See data_preparation/1000G_qc_job.sh for how this path is used)
#TGP_GENOTYPE_DIR="$HOME/projects/def-sgravel/data/genotypes/1000G_EUR_Phase3_plink"

# The path to the 1000G genetic map: (See data_preparation/1000G_qc_job.sh + data_preparation/ukbb_qc_job.sh for how this path is used)
#GENETIC_MAP_DIR="$HOME/projects/def-sgravel/data/genetic_maps/1000GP_Phase3"

module load plink

#cd "$VIPRS_PATH" || exit

# CHR=${1:-22}  # Chromosome number (default 22)
# snp_set=${2:-"hm3"} # The SNP set to use
# ind_keep_file=${3-"data/keep_files/ukbb_qc_individuals.keep"}
# output_dir=${4-"data/ukbb_qc_genotypes"}

# if [ $snp_set == "hm3" ]; then
#   snp_keep="data/keep_files/ukbb_qc_variants_hm3.keep"
# else
#   snp_keep="data/keep_files/ukbb_qc_variants.keep"
#   output_dir="data_all/ukbb_qc_genotypes"
# fi

# mkdir -p "$output_dir"

# output
OUTPUT=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/bed

echo "Set run variables..."

ind_keep_file="/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/keep_files/ukbb_qc_variants.keep"
snp_keep="/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/keep_files/ukbb_qc_variants.keep"

echo "Attempting to create bed file file cor chomosome: ${CH}"

plink2 --bgen "$UKBB_GENOTYPE_DIR/ukb22828_c${CH}_b0_v3.bgen" ref-first \
	   --sample "$UKBB_GENOTYPE_DIR/ukb22828_c${CH}_b0_v3.sample" \
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
	   --out $OUTPUT/ukb22828_c${CH}_b0_v3

#	   --keep "$ind_keep_file" \
#	   --extract "$snp_keep" \

echo "A .bed file for Chromosome ${CH} is hopefully created."

# # original call
# plink2 --bgen "$UKBB_GENOTYPE_DIR/ukb_imp_chr${CHR}_v3.bgen" ref-first \
#       --sample "$UKBB_GENOTYPE_DIR/ukb6728_imp_chr${CHR}_v3_s487395.sample" \
#       --make-bed \
#       --allow-no-sex \
#       --keep "$ind_keep_file" \
#       --extract "$snp_keep" \
#       --hwe "$HWE_CUTOFF" \
#       --mind "$MIND" \
#       --geno "$GENO" \
#       --mac "$MIN_MAC" \
#       --maf "$MIN_MAF" \
#       --max-maf "$MAX_MAF" \
#       --snps-only \
#       --max-alleles 2 \
#       --hard-call-threshold "$HARDCALL_THRES" \
#       --out "$output_dir/chr_${CHR}"

# # Compute the allele frequency and store in the same directory
# # (May be useful in some downstream tasks)
# plink2 --bfile "$output_dir/chr_${CHR}" \
#        --freq cols=chrom,pos,ref,alt1,alt1freq,nobs \
#        --out "$output_dir/chr_${CHR}"

# module load nixpkgs/16.09
# module load plink/1.9b_4.1-x86_64
# # Update the SNP cM position using the HapMap3 genetic map:
# # NOTE: We filter on mac/maf again because plink2 sometimes doesn't filter SNPs
# # properly in the first step (to be checked later).
# plink --bfile "$output_dir/chr_${CHR}" \
#       --cm-map "$GENETIC_MAP_DIR/genetic_map_chr@_combined_b37.txt" \
#       --make-bed \
#       --mac "$MIN_MAC" \
#       --maf "$MIN_MAF" \
#       --out "$output_dir/chr_${CHR}"

# rm -r "$output_dir"/*~

echo "Job finished with exit code $? at: `date`"
