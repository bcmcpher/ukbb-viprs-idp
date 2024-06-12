import pandas as pd

# pull just the filter variables
raw = pd.read_csv('/lustre03/project/6008063/neurohub/ukbb/tabular/archive/49190/ukb49190.csv',
                  na_values='NaN',
                  usecols=['eid', '22006-0.0', '22020-0.0', '22028-0.0', '22021-0.0', '22019-0.0'])
