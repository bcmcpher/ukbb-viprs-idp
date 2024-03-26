
# load dependency
import json
import pandas as pd

# I'll assume v4 is the most accurate
url = "https://open.win.ox.ac.uk/ukbiobank/big40/BIG40-IDPs_v4/IDPs.html"

# ingest data from URL
print(f"Accessing dataframe from html table at URL: {url}")
data = pd.read_html(url)

# format ingested data as a dataframe from a list
print(f"Formatting list of html request into a DataFrame...")
output = pd.DataFrame(data[0])

# drop the column of all missing
# output.drop(index=0, inplace=True)
output.drop(columns = "Unnamed: 4", inplace = True)
output.replace('-', pd.NA)

# write the dataframe to disk as a .csv - w/o an index column
print("Writing formatted dataframe to disk...")
output.to_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_legend.csv", index=False, header=False)

# load the .csv to verify that it's accurate
verify = pd.read_csv("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_legend.csv", header=0, index_col=0, na_values="-", converters={'Pheno': str})
print(f"Loaded IDP DataFrame size: {verify.shape}")

# create a .json dataframe descriptor
datadict = {'Pheno': 'The phenotype ID that corresponds to the downloaded file',
            'UKB ID': 'The UKBB ID of the specific feature',
            'IDP short name': 'A human readable name of UKB variable',
            'Units': 'the unit the variable is measured in',
            'Type': 'whether the measure is a float or integer',
            'Cat.': 'Numeric indication of variable group',
            'Category name': 'Human readable name of variable group',
            'IDP description': 'Short sentence describing the feature',
            'N(disc)': 'Discovery Dataset N',
            'Npar(disc)': 'Discovery Dataset N include X-Chromosome pseudoautosomal region',
            'Nnonpar(disc)': 'Discovery Dataset N exclude X-Chromosome pseudoautosomal region',
            'N(rep)': 'Replication Dataset N',
            'Npar(rep)': 'Replication Dataset N include X-Chromosome psuedoautosomal region',
            'Nnonpar(rep)': 'Replication Dataset N exclude X-Chromosome pseudoatuosomal region',
            'N(all)': 'All Dataset N',
            'Npar(all)': 'All Dataset N include X-Chromosome pseeudoautosomal region',
            'Nnonpar(all)': 'All Dataset N exclude X-Chromosome pseudoatuosomal region',
            'Heritability': 'Genetic Heritability',
            'Heritability(SE)': 'Standard Error of Genetic Heritability'}

with open("/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/idps_legend.json", 'w') as fp:
    json.dump(datadict, fp)
