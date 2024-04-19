import sys
# Make sure to use the latest version of magenpy>=0.1
import magenpy as mgp
from magenpy.utils.system_utils import makedir
import os.path as osp

precision = sys.argv[1]  # Pass the desired precision as an argument (e.g. float32)

# UPDATE THE PATHS HERE:
old_path = "/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ld/chr_{}"
new_path = osp.join(f"/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ld-new/{precision}", "chr_{}")

compressor_name = 'zstd'
compression_level = 9

for i in range(1, 23):

    print(f"> Converting LD matrix for chromosome: {i}")

    makedir(new_path.format(i))

    ld_mat = mgp.LDMatrix.from_ragged_zarr_matrix(old_path.format(i),
                                                  new_path.format(i),
                                                  overwrite=True,
                                                  dtype=precision,
                                                  compressor_name=compressor_name,
                                                  compression_level=compression_level)
    print("Valid conversion:", ld_mat.validate_ld_matrix())
