import pandas as pd
from pathlib import Path

from src.data_processing import write_subset

# load the legend with IDP values in it
ind_path = Path('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_legend.csv')

# load the indicies
idx = pd.read_csv(ind_path, header=0, index_col=0, na_values=["na", "-"], converters={'Pheno': str})

# load the (wrong) data
# build paths to (wrong) data files
# raw_path = Path('/lustre03/project/6008063/neurohub/ukbb/new/Tabular')
# raw = pd.read_csv(Path(raw_path, 'current.csv'), nrows=20)
# traw = pd.read_csv(Path('/lustre03/project/6008063/neurohub/ukbb/tabular/archive/40663/ukb40663.csv'), nrows=20)

# # these are ICA features derived from fMRI features, not distributed.
# # they are non-trivial to reproduce, so I will ignore them
# In [73]: idx['UKB ID'].loc[idx['UKB ID'].str.contains('na')]
# Out [73]:
# 1
# 3915    na
# 3916    na
# 3917    na
# 3918    na
# 3919    na
# 3920    na

# build ses-2 / ses-3 ID's from index legend
idps = idx['UKB ID']
idps = idps.dropna()
idps = idps.astype(int).astype(str)
idp2 = idps + '-2.0'
idp3 = idps + '-3.0'

# # missing functional items
# add 25754-*.1-21
# add 25755-*.1-55
# add 25752-*.1-210
# add 25753-*.1-1485

print("Loading ses-2 data...")
write_subset('/lustre03/project/6008063/neurohub/ukbb/tabular/archive/49190/ukb49190.csv',
             '/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-2.csv',
             colnames=idp2.to_list(),
             fn_to_apply=(lambda df: df.dropna(axis='index', how='all')),
)
print("Done.")

print("Loading ses-3 data...")
write_subset('/lustre03/project/6008063/neurohub/ukbb/tabular/archive/49190/ukb49190.csv',
             '/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-3.csv',
             colnames=idp3.to_list(),
             fn_to_apply=(lambda df: df.dropna(axis='index', how='all')),
)
print("Done.")

print("Loading data to fix headers...")
ses2 = pd.read_csv('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-02.csv')
ses2.columns = ses2.columns.str.removesuffix('-2.0')
ses2.to_csv('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-02.csv')

ses3 = pd.read_csv('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-03.csv')
ses3.columns = ses2.columns.str.removesuffix('-3.0')
ses3.to_csv('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-03.csv')

# # because why would it be obvious which file has the data in it...
# raw = pd.read_csv('/lustre03/project/6008063/neurohub/ukbb/tabular/archive/49190/ukb49190.csv', na_values='NaN',
#                   usecols=pd.concat([idp2, idp3]), chunksize=10000)

# print("Data loaded.")

# # get subject ID as the row names
# rown = raw['eid']

# # subset to subject ID / IDP variables
# idp2_data = raw[idp2]
# idp3_data = raw[idp3]

# # assign row names for subject ID
# idp2_data.index = rown
# idp3_data.index = rown

# # assign generic variable names for symmetric selection
# idp2_data.columns = idps
# idp3_data.columns = idps

# # drop missing and write to disk
# idp2_data = idp2_data.dropna(how='all')
# idp3_data = idp3_data.dropna(how='all')

# # write data to disk
# idp2_data.to_csv(Path('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-02.csv'))
# idp3_data.to_csv(Path('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-03.csv'))

# # load the data to check
# zz2 = pd.read_csv(Path('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-02.csv'), index_col='eid')
# zz3 = pd.read_csv(Path('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-03.csv'), index_col='eid')

#
# find the keep variables
#

# grab demographics

# ['IID'] > 0  # eid
# ['in.white.British.ancestry.subset'] == 1  # 22006
# ['putative.sex.chromosome.aneuploidy'] == 0  # 22019
# ['used.in.pca.calculation'] == 1  # 22020
# ['excess.relatives'] == 0  # 22021?
# ['in.Phasing.Input.chr1_22'] == 1  # 22028

# because why would it be obvious which file has the data in it...
# pull just the filter variables
raw = pd.read_csv('/lustre03/project/6008063/neurohub/ukbb/tabular/archive/49190/ukb49190.csv', na_values='NaN',
                  usecols=['eid', '22006-0.0', '22020-0.0', '22028-0.0', '22021-0.0', '22019-0.0'])

# rename them to match other file
raw.columns = ['IID', 'in.white.British.ancestry.subset', 'putative.sex.chromosome.aneuploidy', 'used.in.pca.calculation', 'excess.relatives', 'in.Phasing.Input.ch1_22']

# save them

# create the subset list of IID (eid)
out = raw.loc[(raw['IID'] > 0) & (raw['in.white.British.ancestry.subset'] == 1) & (raw['used.in.pca.calculation'] == 1) & (raw['in.Phasing.Input.ch1_22'] == 1) & (raw['excess.relatives'] == 0) & (raw['putative.sex.chromosome.aneuploidy'] == 0)]

# out is IID and FID is IID (already excluding relatives sufficiently?)
out = out['IID']
# out['FID'] = out['IID'] # does this strictly need FID?

# reorder / rename variables?

# write the keep file
out.to_csv('/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/keep_files/ukbb_qc_variants.keep', sep='\t', header=False, index=False)

#
# other demographics?
#
