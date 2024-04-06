
import argparse
import pandas as pd
from pathlib import Path

# PARSE IDP from input
parser = argparse.ArgumentParser(description='Create phenotype file for VIPRS evaluation.')

# add input to argparse
parser.add_argument('pheno', type=str,
                    help='The unzipped phenotype file to load.')
parsed.add_argument('keep', type = str,

# parse
args = parser.parse_args()

# extract PHENO.txt
pheno = args.pheno

# paths to run
projdir = "/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp"
datadir = Path(projdir, "data")
scratch = Path(datadir, "idps-fixed")

print("Loading the IDPs Legend to extract sample size...")

# load the summary data
summary = pd.read_csv(Path(datadir, "idps_legend.csv"),
                      header=0,
                      index_col=0,
                      na_values="-",
                      converters={'Pheno': str})

# get the N - make sure these are all present - some categories of N are missing...
sample_size = summary.loc[summary['Pheno'] == pheno, 'N(all)'].values[0]

print(f" -- Sample Size: {sample_size}")
print(f"Loading the precomputed GWAS summary data for IDP: {pheno}")

# load the input
df = pd.read_csv(Path(scratch, f"{pheno}.txt"), delim_whitespace=True)

# assign the sample size based on the loaded feature
df['N'] = sample_size

print("Writing corrected IDP summary data to disk...")

# fix the column names so VIPRS can read it 
df.rename(columns={'chr':'CHR', 'pos':'POS', 'beta':'BETA', 'se':'SE', 'a1':'A1', 'a2':'A2', 'rsid':'SNP'}, inplace=True)

# write appened / fixed file
df.to_csv(Path(scratch, f"{pheno}-fixed.txt"), sep="\t", index=False)
