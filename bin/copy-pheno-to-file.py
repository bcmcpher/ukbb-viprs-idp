import argparse
import pandas as pd
from pathlib import Path

# PARSE IDP from input
parser = argparse.ArgumentParser(description='Create phenotype file for VIPRS evaluation.')

# add input to argparse
parser.add_argument('pheno', type=str,
                    help='The unzipped phenotype file to load.')
parser.add_argument('outfile', type=str,
                    help='The output file to write the extracted phenotype into.')
# parser.add_argument('keep', type=str,
#                     help='The optional keep file to apply to the filter the rows.')

# parse
args = parser.parse_args()

# extract PHENO.txt
pheno = args.pheno
outfile = args.outfile
# keep = args.keep

# paths to run
projdir = "/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp"
datadir = Path(projdir, "data")
keepdir = Path(datadir, "keep_files")
outsdir = Path(datadir, "viprs-evals")

print("Loading the IDPs Legend to find UKBB index...")

# load the summary data
summary = pd.read_csv(Path(datadir, "idps_legend.csv"), header=0, index_col=0, na_values="-", converters={'Pheno': str})

# pick the column index to load
ukbb_var = summary.loc[summary['Pheno'] == pheno, 'UKB ID'].values[0]

# The expected format is: FID IID phenotype (no header), tab-separated.

# add participant id, selected variable
usecols = ['eid', ukbb_var]

# load just the columns to write
data = pd.read_csv(Path(datadir, "ukbb_idps_ses-2.csv"), usecols=usecols)

# this assumes no related individuals kept - family ID is just a copy of subj ID
data['fid'] = data.loc[:, 'eid']

# reorder columns for clean export
data = data[['fid', 'eid', ukbb_var]]

# load keep data
krows = pd.read_csv(Path(keepdir, "ukbb_qc_variants.keep"))

# keep and sort the IDs that having imaging data and match keep file
df = data.loc[data['eid'].isin(set(krows.squeeze()))]

# drop missing from final out (?)
# df.dropna(inplace=True)

# write appened / fixed file
# df.to_csv(Path(outsdir, f"{pheno}-eval.tsv"), sep="\t", index=False, header=False)
df.to_csv(outfile, sep="\t", index=False, header=False)
