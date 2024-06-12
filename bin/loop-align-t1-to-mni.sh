#!/bin/bash

echo " *** Starting batch extraction of WM stats ***"

for dir in /tractoflow_results/*/;
do
    dir=${dir%*/}
    subj=${dir##/*sub-}
    subj=${subj%%_*}
    sess=${dir#*ses-}
    echo "Aligning sub-${subj}_ses-${sess}:"

    # if the output file already exists, skip to next
    if [ -e /lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ohbm/sub-${subj}_ses-${sess}_wm-stats.csv ]; then
	echo " -- Output for ${subj}_${sess} exists. Skipping."
	continue
    else
	echo " -- Creating WM stats output for sub-${subj}_ses-${sess}..."
    fi
    
    # where to make intermediary files
    WORKDIR=/scratch/bcmcpher/ohbm/sub-${subj}_ses-${sess}
    mkdir -p $WORKDIR

    # build BIDS name
    BIDSSTEM=/tractoflow_results/sub-${subj}_ses-${sess}

    # build input file paths
    T1=${BIDSSTEM}/Resample_T1/sub-${subj}_ses-${sess}__t1_resampled.nii.gz
    FA=${BIDSSTEM}/DTI_Metrics/sub-${subj}_ses-${sess}__fa.nii.gz
    MD=${BIDSSTEM}/DTI_Metrics/sub-${subj}_ses-${sess}__md.nii.gz
    
    # reference templates
    MNI=/usr/share/fsl/data/standard/MNI152_T1_1mm.nii.gz
    JHU=/lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/JHU-ICBM-labels-1mm.nii.gz
    
    # existing affine xform file
    T12DWI=${BIDSSTEM}/Register_T1/sub-${subj}_ses-${sess}__output0GenericAffine.mat

    # output stem of new affine
    MNI2T1=$WORKDIR/sub-${subj}_ses-${sess}__mni-to-t1

    # linear registration of T1 to MNI
    echo " -- Estimating T1 to MNI for composite xform..."
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
    echo " -- Applying MNI -> T1 -> DWI xform to labels..."
    antsApplyTransforms --dimensionality 3 \
			--input $JHU \
			--reference-image $FA \
			--output $WORKDIR/sub-${subj}_ses-${sess}_wm-labels.nii.gz \
			--interpolation NearestNeighbor \
			--transform $T12DWI ${MNI2T1}_0GenericAffine.mat
    
    # call python fxn to build average values w/ xformed labels
    echo " -- Extracting WM statistics..."
    python /lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/bin/extract-values-from-labels.py $subj $sess /lustre03/project/6018311/bcmcpher/ukbb-viprs-idp/data/ohbm
    
done
