#!/bin/bash
## ---------------------------
## [script name] 
## SCRIPT to .
##
## By Shuai Wang
## ---------------------------

## Set environment (packages, functions, working path etc.)
# Platform
platform='mesoc'
case "$platform" in
	mesoc)
		dir_main='/CP00'                       # the project Main folder @mesocentre
	  	export PATH="$dir_main/nitools:$PATH"  # setup tools if @mesocentre
	  	njob=16
	  	;;
	local)
		dir_main='/media/wang/BON/Projects/CP00'  # the project Main folder @totti
	  	njob=4
	  	;;
	*)
		echo -e "Please input a valid platform!"
	  	exit 1
esac
# Setup path
dir_data="$dir_main/AudioVisAsso"              # experiment Data folder (BIDS put into fMRIPrep)
dir_fmri="$dir_data/derivatives/fmriprep"      # fMRIPrep output folder
dir_afni="$dir_data/derivatives/afni"          # AFNI output folder
dir_mask="$dir_data/derivatives/masks"         # masks folder
dir_mvpa="$dir_data/derivatives/multivariate"  # MVPA/RSA folder
# Processing parameters
readarray subjects < $dir_main/CP00_subjects.txt
readarray rois < $dir_afni/group_masks_labels-RSE.txt
n_subjects=${#subjects[@]}
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## Beta-series connectivity
task='task-AudioVisAssos1word'
dir_task="$dir_mvpa/group"
for subj in ${subjects[@]};do
	dir_subj="$dir_mvpa/$subj/betas_afni"
	# Extract beta-series
	for iroi in ${rois[@]};do
		if [ "${iroi::1}" = 'i' ];then
            f_roi="$dir_mask/$subj/${subj}_${spac}_mask-${iroi}.nii.gz"
        else
            f_roi="$dir_mask/group/group_${spac}_mask-${iroi}.nii.gz"
        fi
		f_beta="$dir_subj/${subj}_LSS_nilearn.nii.gz"  # WA, WV, PA, PV: 60 trials each
		f_beta_vis="$dir_subj/${subj}_${task}_mask-${iroi}_beta_WV+PV.1D"  # ROI time-series
		f_beta_aud="$dir_subj/${subj}_${task}_mask-${iroi}_beta_WA+PA.1D"  # ROI time-series
		if [ ! -f $f_beta_vis ];then
			3dmaskave -mask $f_roi -quiet $f_beta[60..119,180..239] > $f_beta_vis
			3dmaskave -mask $f_roi -quiet $f_beta[0..59,120..179] > $f_beta_aud
		fi
	done
	# Calculate
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
