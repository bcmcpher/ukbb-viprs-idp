import warnings
import pandas as pd

# load the demographic data for each time point
ses2 = pd.read_csv("ukbb_idps_ses-2.csv", header=0, index_col=0)
ses3 = pd.read_csv("ukbb_idps_ses-3.csv", header=0, index_col=0)

# sanity check that the rows match
if all(ses2.columns == ses3.columns):
    cols = ses2.columns
    cols = cols[1:]  # drop eid
else:
    warnings.warn("Columns somehow don't match.")

# for every column
for var in cols:

    # pull temp frames of ID and variable
    tmp2 = ses2[['eid', var]]
    tmp3 = ses3[['eid', var]]

    # merge them together
    tmp = tmp2.merge(tmp3,
                     left_on='eid',
                     right_on='eid',
                     suffixes=('_t1', '_t2'))
    # by default, this drops missing

    # take difference / ratio
    tmp['diff'] = tmp[var + '_t2'] - tmp[var + '_t1']
    # +value = grows over time; -value = shrinks over time

    tmp['ratio'] = tmp[var + '_t2'] - tmp[var + '_t1']
    # >1 = grows over time; <1 = shrinks over time

    # create the outputs
    odiff = tmp[['eid', 'eid', 'diff']]
    odiff.columns = ['fid', 'iid', var]
    odiff.to_csv(f'/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps-compare/{var}-diff.tsv', sep='\t', index=False, header=False)

    oratio = tmp[['eid', 'eid', 'ratio']]
    oratio.columns = ['fid', 'iid', var]
    oratio.to_csv(f'/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps-compare/{var}-ratio.tsv', sep='\t', index=False, header=False)
