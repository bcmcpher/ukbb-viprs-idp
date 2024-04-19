import warnings
import pandas as pd

#print("Loading the IDPs Legend to find UKBB index...")

# load the summary data
#summary = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_legend.csv"), header=0, index_col=0, na_values="-", converters={'Pheno': str})

print("Loading the IDP data...")

# load the demographic data for each time point
ses2 = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-2.csv", header=0, index_col=0, na_values='NaN')
ses3 = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ukbb_idps_ses-3.csv", header=0, index_col=0, na_values='NaN')

print("Loading the unrelated subjects keep file...")

# load keep data
krows = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/keep_files/ukbb_qc_variants.keep")

# sanity check that the columns match
if all(ses2.columns == ses3.columns):
    cols = ses2.columns
    cols = cols[1:]  # drop eid
else:
    warnings.warn("Columns somehow don't match.")

# for every column
for var in cols:

    # write unrelated pheno for time1 / time2
    # keep and sort the IDs that having imaging data and match keep file
    # df2 = ses2.loc[data['eid'].isin(set(krows.squeeze()))]
    # df3 = ses3.loc[data['eid'].isin(set(krows.squeeze()))]

    # drop missing from final out (?)
    # df.dropna(inplace=True)

    # write appened / fixed file
    # df.to_csv(Path(outsdir, f"{pheno}-eval.tsv"), sep="\t", index=False, header=False)
    # df2.to_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps-compare/{var}_ukbb-full_ses2_evaluate.tsv", sep="\t", index=False, header=False)
    # df3.to_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps-compare/{var}_ukbb-full_ses3_evaluate.tsv", sep="\t", index=False, header=False)

    print(f"Creating longitudinal change for : {var}")

    # pull temp frames of ID and variable
    tmp2 = ses2[['eid', var]]
    tmp3 = ses3[['eid', var]]

    # subset the rows to the keep indices
    df2 = tmp2.loc[data['eid'].isin(set(krows.squeeze()))]
    df3 = tmp3.loc[data['eid'].isin(set(krows.squeeze()))]

    # write files to disk after subsetting to keep indices
    df2.to_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps-compare/{var}_ukbb-full_ses2_evaluate.tsv", sep="\t", index=False, header=False)
    df3.to_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps-compare/{var}_ukbb-full_ses3_evaluate.tsv", sep="\t", index=False, header=False)

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

    # create the output files
    odiff = tmp[['eid', 'eid', 'diff']]
    odiff.columns = ['fid', 'iid', var]  # not necessary
    odiff.to_csv(f'/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps-compare/{var}-diff.tsv', sep='\t', index=False, header=False)

    oratio = tmp[['eid', 'eid', 'ratio']]
    oratio.columns = ['fid', 'iid', var]  # not necessary
    oratio.to_csv(f'/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps-compare/{var}-ratio.tsv', sep='\t', index=False, header=False)
