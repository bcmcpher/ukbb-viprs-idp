import warnings
import pandas as pd

print("Loading the data...")

# load the demographic data for each time point
ses2 = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-2.csv", header=0, index_col=0, na_values='NaN')
ses3 = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-3.csv", header=0, index_col=0, na_values='NaN')

# load the legend to get the fixed id
data = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_legend.csv", header=0, index_col=0, na_values="-", converters={'Pheno': str})

# load keep data
krows = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/keep_files/ukbb_qc_observations.keep")

# run ID - changes w/ different krows (keepID)
runid = "ukbb-qc"

# sanity check that the rows match
if all(ses2.columns == ses3.columns):
    cols = ses2.columns
    cols = cols[1:]  # drop eid
else:
    warnings.warn("Columns somehow don't match.")

# get the length for logging
nvar = len(cols)

print("Beginning loop of variables to export (N={len(cols)}):")

# for every column
for idx, var in enumerate(cols):

    # get the pheno index
    pheno = data.loc[data['UKB ID'] == var]['Pheno']

    # deal w/ repeated vars
    if len(pheno) > 1:
        print(" -- Phenotype / Variable {pheno} / {var} has more than one row (FCONN). Skip.")
        continue
    else:
        pheno = pheno.item()

    print(f" -- Creating Phenotype / Variable: {pheno} / {var} (IDX: {idx}/{nvar})")

    # pull temp frames of ID and variable
    tmp2 = ses2[['eid', var]]
    tmp3 = ses3[['eid', var]]

    # merge them together
    tmp = tmp2.merge(tmp3,
                     left_on='eid',
                     right_on='eid',
                     suffixes=('_t1', '_t2'))
    # by default, this drops missing

    # if strings are loaded (for some reason), skip to next var
    if any(tmp.dtypes[1:] == 'object'):
        warnings.warn(f" -- Variable {var} is a string")
        continue

    # take difference / ratio
    tmp['diff'] = tmp[var + '_t2'] - tmp[var + '_t1']
    # +value = grows over time; -value = shrinks over time

    tmp['ratio'] = tmp[var + '_t2'] - tmp[var + '_t1']
    # >1 = grows over time; <1 = shrinks over time

    # reorder columns for clean export
    pdata = tmp2[['eid', 'eid', var]]
    pdat2 = tmp3[['eid', 'eid', var]]

    # keep and sort the IDs that having imaging data and match keep file
    pdata = pdata.loc[tmp2['eid'].isin(set(krows.squeeze()))]
    pdata.columns = ['fid', 'iid', pheno]
    pdata.to_csv(f'/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_{runid}/{pheno}_{runid}_baseline-eval.tsv', sep='\t', index=False, header=False)
    print(f" --  -- Saved baseline UKBB-{var} to phenotype index {pheno} (N={pdata.shape[0]})")

    pdat2 = pdat2.loc[tmp3['eid'].isin(set(krows.squeeze()))]
    pdat2.columns = ['fid', 'iid', pheno]
    pdat2.to_csv(f'/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_{runid}/{pheno}_{runid}_followup-eval.tsv', sep='\t', index=False, header=False)
    print(f" --  -- Saved followup visit UKBB-{var} to phenotype index {pheno} (N={pdata.shape[0]})")

    # create the output files
    odiff = tmp[['eid', 'eid', 'diff']]
    odiff.columns = ['fid', 'iid', pheno]  # not necessary
    odiff.to_csv(f'/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_{runid}/{pheno}_{runid}_difference.tsv', sep='\t', index=False, header=False)
    print(f" --  -- Saved T2-T1 difference of UKBB-{var} to phenotype index {pheno} (N={odiff.shape[0]})")

    oratio = tmp[['eid', 'eid', 'ratio']]
    oratio.columns = ['fid', 'iid', pheno]  # not necessary
    oratio.to_csv(f'/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_{runid}/{pheno}_{runid}_ratio.tsv', sep='\t', index=False, header=False)
    print(f" --  -- Saved T2/T1 ratio of UKBB-{var} to phenotype index {pheno} (N={odiff.shape[0]})")
