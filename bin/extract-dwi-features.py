
import numpy as np
from nibabel.affines import from_matvec, to_matvec, apply_affine

# participant / session arguments
subj = "1000083"
sess = "2"

# T1 to DWI affine
sub2mni = f"Register_T1/sub-{subj}_ses-{sess}__output0GenericAffine.mat"

# T1 file to align
t1 = f"Resample_T1/sub-{subj}_ses-{sess}__t1_resampled.nii.gz"

# DWI param maps to extract from
fa = f"DTI_Metrics/sub-{subj}_ses-{sess}__fa.nii.gz"
md = f"DTI_Metrics/sub-{subj}_ses-{sess}__md.nii.gz"

# atlas file
mniref = "/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/brain/MNI152_T1_1mm_brain.nii.gz"
labels = "/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/brain/JHU-ICBM-labels-1mm.nii.gz"

# estimate linear alignment of T1 brain to template

# move DWI-metrics from DWI -> T1 -> Template w/ previous and new transform

# compute mean w/in each label on transformed space

# save results w/ UKBB column labels
