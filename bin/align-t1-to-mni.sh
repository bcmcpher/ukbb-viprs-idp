#!/bin/bash

# eventual arguments
SUBJ=$1
SESS=$2

# where to make intermediary files
WORKDIR=./work

# build BIDS name
BIDSSTEM=sub-${SUBJ}_ses-${SESS}

#
# TODO - set paths to these files
#

# build input file paths
T1=${BIDSSTEM}__t1_resampled.nii.gz
FA=${BIDSSTEM}__fa.nii.gz
MD=${BIDSSTEM}__md.nii.gz

# reference templates
MNI=MNI152_T1_1mm.nii.gz
JHU=JHU-ICBM-labels-1mm.nii.gz

# existing affine xform file
T12DWI=${BIDSSTEM}__output0GenericAffine.mat

# output stem of new affine
MNI2T1=${BIDSSTEM}__mni-to-t1

#
# end of paths TODO
#

# linear registration of T1 to MNI
echo "Estimating T1 to MNI for composite xform..."
antsRegistration --dimensionality 3 --float 0 \
				 --output [$WORKDIR/${MNI2T1}_,$WORKDIR/${MNI2T1}_Warped.nii.gz] \
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
					--output $WORKDIR/test-labels.nii.gz \
					--interpolation NearestNeighbor \
					--transform $T12DWI $WORKDIR/${MNI2T1}_0GenericAffine.mat

# call python fxn to build average values w/ xformed labels
python ./extract-values-from-labels.py $1 $2 ./
