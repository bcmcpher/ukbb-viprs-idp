import argparse
import pandas as pd
from pathlib import Path

# PARSE IDP from input
parser = argparse.ArgumentParser(description='Create phenotype file for VIPRS evaluation.')

# add input to argparse
parser.add_argument('pheno', type=str,
                    help='The unzipped phenotype file to load.')
parser.add_argument('keep', type=str,
                    help='The optional keep file to apply to the filter the rows.')

# parse
args = parser.parse_args()

# extract PHENO.txt
pheno = args.pheno
keep = args.keep

# paths to run
projdir = "/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp"
datadir = Path(projdir, "data")
keepdir = Path(datadir, "keep_files")
outsdir = Path(datadir, "viprs_evals")

print("Loading the IDPs Legend to extract sample size...")

# load the summary data
summary = pd.read_csv(Path(datadir, "idps_legend.csv"), header=0, index_col=0, na_values="-", converters={'Pheno': str})

# pick the column index to load
ukbb_var = summary.loc[summary['Pheno'] == pheno, 'UKB ID'].values[0]

# The expected format is: FID IID phenotype (no header), tab-separated.

# add participant id, selected variable (need FID?)
usecols = ['eid', ukbb_var]

# load just the columns to write
data = pd.read_csv(Path(datadir, "ukbb_idps_ses-2.csv"), index_col=0, usecols=usecols)

# if keep is passed
if keep:

    # load keep data
    krows = pd.read_csv(Path(keepdir, "ukbb_qc_variants.keep"))

    # keep and sort the IDs that having imaging data and match keep file
    df = data.loc[sorted(list(set(data.index) & set(krows.squeeze())))]

    # drop missing from final out
    # df.dropna(inplace=True)

# write appened / fixed file
df.to_csv(Path(outsdir, f"{pheno}-eval.txt"), sep="\t", header=False)
