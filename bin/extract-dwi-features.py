import nibabel as nib

from dipy.viz import regtools
# from dipy.io.image import load_nifti
# from dipy.align.imaffine import (transform_centers_of_mass,
#                                  AffineMap,
#                                  MutualInformationMetric,
#                                  AffineRegistration)
# from dipy.align.transforms import (TranslationTransform3D,
#                                    RigidTransform3D,
#                                    AffineTransform3D)

from dipy.align import affine_registration, register_dwi_to_template

# participant / session arguments
subj = "1000083"
sess = "2"

# # T1 to DWI affine
# sub2mni = f"Register_T1/sub-{subj}_ses-{sess}__output0GenericAffine.mat"

# # T1 file to align
# anat = f"Resample_T1/sub-{subj}_ses-{sess}__t1_resampled.nii.gz"

# # DWI param maps to extract from
# fa = f"DTI_Metrics/sub-{subj}_ses-{sess}__fa.nii.gz"
# md = f"DTI_Metrics/sub-{subj}_ses-{sess}__md.nii.gz"

# # atlas file
# mniref = "/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/brain/MNI152_T1_1mm_brain.nii.gz"
# labels = "/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/brain/JHU-ICBM-labels-1mm.nii.gz"

# input files - set up parsing
sub2mni = f"sub-{subj}_ses-{sess}__output0GenericAffine.mat"
t1 = f"sub-{subj}_ses-{sess}__t1_resampled.nii.gz"
fa = f"sub-{subj}_ses-{sess}__fa.nii.gz"
md = f"sub-{subj}_ses-{sess}__md.nii.gz"

# template files
mniref = "MNI152_T1_1mm.nii.gz"
labels = "JHU-ICBM-labels-1mm.nii.gz"

#
# load the data - drop unused parts
#

# ConvertTransformFile 3 sub2mni sub2mni.txt
# then I have to load it...

t1_nib = nib.load(t1)
t1_aff = t1_nib.affine
t1_dat = t1_nib.get_fdata()

fa_nib = nib.load(fa)
fa_aff = fa_nib.affine
fa_dat = fa_nib.get_fdata()

md_nib = nib.load(md)
md_aff = md_nib.affine
md_dat = md_nib.get_fdata()

mn_nib = nib.load(mniref)
mn_aff = mn_nib.affine
mn_dat = mn_nib.get_fdata()

lb_nib = nib.load(labels)
lb_aff = lb_nib.affine
lb_dat = lb_nib.get_fdata()

#
# estimate linear alignment of T1 brain to template
#

# parameters for estimating alignment
nbins = 16  # 32
pipeline = ["center_of_mass", "translation", "rigid", "affine"]
level_iters = [5000, 500, 50]  # [10000, 1000, 100]
sigmas = [3.0, 1.0, 0.0]
factors = [4, 2, 1]

# estimate t1 to mni affine
xformed_img, reg_affine = affine_registration(
    t1_dat,  # moving
    mn_dat,  # static
    moving_affine=t1_aff,  # moving affine
    static_affine=mn_aff,  # static affine
    nbins=nbins,
    metric='MI',
    pipeline=pipeline,
    level_iters=level_iters,
    sigmas=sigmas,
    factors=factors)

# visually check alignment
# regtools.overlay_slices(mn_dat, xformed_img, None, 0, "Static", "Transformed")
# regtools.overlay_slices(mn_dat, xformed_img, None, 1, "Static", "Transformed")
# regtools.overlay_slices(mn_dat, xformed_img, None, 2, "Static", "Transformed")

# move DWI-metrics from DWI -> T1 -> Template w/ previous and new transform


# compute mean w/in each label on transformed space

# save results w/ UKBB column labels
