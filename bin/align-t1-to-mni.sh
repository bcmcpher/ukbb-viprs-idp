#!/bin/bash

# eventual arguments
SUBJ=$1
SESS=$2

# where to make intermediary files
WORKDIR=/scratch/bcmcpher/ohbm/sub-${SUBJ}_ses-${SESS}
mkdir -p $WORKDIR

# build BIDS name
BIDSSTEM=/tractoflow_results/sub-${SUBJ}_ses-${SESS}

# TODO - set paths to these files

# build input file paths
T1=${BIDSSTEM}/Resample_T1/sub-${SUBJ}_ses-${SESS}__t1_resampled.nii.gz
FA=${BIDSSTEM}/DTI_Metrics/sub-${SUBJ}_ses-${SESS}__fa.nii.gz
MD=${BIDSSTEM}/DTI_Metrics/sub-${SUBJ}_ses-${SESS}__md.nii.gz

# reference templates
MNI=/usr/share/fsl/data/standard/MNI152_T1_1mm.nii.gz
JHU=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/JHU-ICBM-labels-1mm.nii.gz

# existing affine xform file
T12DWI=${BIDSSTEM}/Register_T1/sub-${SUBJ}_ses-${SESS}__output0GenericAffine.mat

# output stem of new affine
MNI2T1=$WORKDIR/sub-${SUBJ}_ses-${SESS}__mni-to-t1

# end of paths TODO

# linear registration of T1 to MNI
echo "Estimating T1 to MNI for composite xform..."
antsRegistration --dimensionality 3 --float 0 \
				 --output [${MNI2T1}_,${MNI2T1}_Warped.nii.gz] \
				 --interpolation Linear \
				 --winsorize-image-intensities [0.005,0.995] \
				 --use-histogram-matching 0 \
				 --initial-moving-transform [$T1,$MNI,1] \
				 --transform Rigid[0.1] \
				 --metric MI[$T1,$MNI,1,32,Regular,0.25] \
				 --convergence [1000x500x250x100,1e-6,10] \
				 --shrink-factors 8x4x2x1 \
				 --smoothing-sigmas 3x2x1x0vox \
				 --transform Affine[0.1] \
				 --metric MI[$T1,$MNI,1,32,Regular,0.25] \
				 --convergence [1000x500x250x100,1e-6,10] \
				 --shrink-factors 8x4x2x1 \
				 --smoothing-sigmas 3x2x1x0vox

# move labels through MNI -> T1 -> DWI w/ new and existing xforms
echo "Applying MNI -> T1 -> DWI xform to labels..."
antsApplyTransforms --dimensionality 3 \
					--input $JHU \
					--reference-image $FA \
					--output $WORKDIR/sub-${SUBJ}_ses-${SESS}_wm-labels.nii.gz \
					--interpolation NearestNeighbor \
					--transform $T12DWI ${MNI2T1}_0GenericAffine.mat

# call python fxn to build average values w/ xformed labels
python /lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/extract-values-from-labels.py $1 $2 /lustre03/project/6018311/bcmcpher/ukbb-virps-idp/data/ohbm
