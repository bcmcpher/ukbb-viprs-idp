import argparse
import itertools
import xml.etree.ElementTree as ET

import nibabel as nib
import numpy as np
import pandas as pd


# PARSE IDP from input
parser = argparse.ArgumentParser(description='Extract IDPs from TractoFlow output.')

# add input to argparse
parser.add_argument('subj', type=str,
                    help='The subject ID.')
parser.add_argument('sess', type=str,
                    help='The session of the subject.')
parser.add_argument('output', type=str,
                    help='The output folder for the file')

# parse
args = parser.parse_args()

# extract PHENO.txt
subj = args.subj
sess = args.sess
output_path = args.output

# the "parsed" input file stems
fa_file = f"/tractoflow_results/sub-{subj}_ses-{sess}/DTI_Metrics/sub-{subj}_ses-{sess}__fa.nii.gz"
md_file = f"/tractoflow_results/sub-{subj}_ses-{sess}/DTI_Metrics/sub-{subj}_ses-{sess}__md.nii.gz"
df_file = f"{output_path}/sub-{subj}_ses-{sess}_wm-stats.csv"

# the unchanging template files
jh_file = f"/scratch/bcmcpher/ohbm/sub-{subj}_ses-{sess}/sub-{subj}_ses-{sess}_wm-labels.nii.gz"
jh_fxml = "/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/JHU-labels.xml"

# load the ref volume b/c I have to fix names NOW
jh_dat = nib.load(jh_file).get_fdata()
jh_unq = np.unique(jh_dat[jh_dat > 0])

# import legend file for
data = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_legend.csv",
                   header=0, index_col=0,
                   na_values="-",
                   converters={'Pheno': str})

# just read the xml directly
tree = ET.parse(jh_fxml)

# parse and load the root of the document
root = tree.getroot()

# create empty label list
jh_labs = []
jh_name = []
jh_idx = []

# for both modalities
for ob in ["FA", "MD"]:
    # for every possible label
    for idx, dt in enumerate(root[1]):
        # rebuild the stupid name
        tvar = f'IDP_dMRI_TBSS_{ob}_{dt.text.replace(" ", "_")}'
        # if the stupid name exists
        if any(data["IDP short name"] == tvar):
            # pull the UKB ID value for output name
            val = data.loc[data["IDP short name"] == tvar, "UKB ID"].item()
            # print(f"Adding UKB ID: {val} at index {idx} for variable: {tvar}")
            jh_labs.append(val)
            jh_name.append(dt.text.replace(" ", "_"))
            jh_idx.append(idx)  # of course this is too long

# cut the list in half - found labels repeat
jh_idx = jh_idx[:len(jh_idx)//2]
jh_name = jh_name[:len(jh_name)//2]

# create the variable names for the data frame
var_names = ["participant_id"] + jh_labs

#
# load the data and extract the averages
#

# just load the data blocks
fa_dat = nib.load(fa_file).get_fdata()
md_dat = nib.load(md_file).get_fdata()

# preallocate outputs
fa_out = []
md_out = []

# for the every label, pull the average of the values
for idx, lab in enumerate(jh_idx):
    # print(f"Extracting: {lab} - {jh_name[idx]}")
    fa_out.append(np.mean(fa_dat[jh_dat == lab]))
    md_out.append(np.mean(md_dat[jh_dat == lab]))

# append all output variables as a list
out = list(itertools.chain([subj], fa_out, md_out))

# create the 1 subject dataframe
df = pd.DataFrame(out).T

# assign the ID / UKB labels
df.columns = var_names

# write the dataframe out so it can easily be read back in
df.to_csv(df_file, header=True, index=False)

# stack together the single row data frames
# zz = pd.concat([df1, df2, df3, ...])
