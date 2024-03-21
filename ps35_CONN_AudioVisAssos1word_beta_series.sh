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
dir_conn="$dir_data/derivatives/connectivity"
# Processing parameters
readarray subjects < $dir_main/CP00_subjects.txt
readarray rois < $dir_afni/group_masks_labels-RSE.txt
n_subjects=${#subjects[@]}
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
masks=("gm-lVP" "gm-AAL3-MultimodalLanguage")
seeds=("lvOT-RSE-Vis" "lvOT-RSE-Aud" "ilvOT-RSE-Vis" "ilvOT-RSE-Aud")
task='task-AudioVisAssos1word'
conditions=("WV+PV" "WA+PA")
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## Beta-series connectivity
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
	# Calculate seed-based voxel-wise connectivity
	for imask in ${masks[@]};do
		f_mask="$dir_mask/group/group_${spac}_mask-${imask}.nii.gz"
		for iseed in ${seeds[@]};do
			f_seed_vis="$dir_subj/${subj}_${task}_mask-${iseed}_beta_WV+PV.1D"
			f_seed_aud="$dir_subj/${subj}_${task}_mask-${iseed}_beta_WA+PA.1D"
			f_conn_vis="$dir_conn/${subj}_${task}_mask-${imask}_seed-${iseed}_WV+PV+tlrc"
			f_conn_aud="$dir_conn/${subj}_${task}_mask-${imask}_seed-${iseed}_WA+PA+tlrc"
			if [ ! -f "${f_conn_vis}.HEAD" ];then
				3dTcorr1D -spearman -Fisher -mask $f_mask -prefix $f_conn_vis $f_beta[60..119,180..239] $f_seed_vis
				3dTcorr1D -spearman -Fisher -mask $f_mask -prefix $f_conn_aud $f_beta[0..59,120..179] $f_seed_aud
			fi
		done
	done
done
## ---------------------------

## Group T-tests
for imask in ${masks[@]};do
	f_mask="$dir_mask/group/group_${spac}_mask-${imask}.nii.gz"
	if [ "$imask" = 'gm-lVP' ];then mask='lVP'; fi
	if [ "$imask" = 'gm-AAL3-MultimodalLanguage' ];then mask='MLang'; fi
	for iseed in ${seeds[@]};do
		for icond in ${conditions[@]};do
			# T-test on one sample with FWE estimation
			f_test="$dir_conn/group/stats.${mask}.group_${task}_mask-${imask}_seed-${iseed}_${icond}"
			f_resid="$dir_conn/group/stats.${mask}.group.resid_${task}_mask-${imask}_seed-${iseed}_${icond}+tlrc"
			f_acf="$dir_conn/group/stats.${mask}.group.ACF_${task}_mask-${imask}_seed-${iseed}_${icond}"
			f_sim="$dir_conn/group/stats.${mask}.group.ACFc_${task}_mask-${imask}_seed-${iseed}_${icond}"
			f_fwe="$dir_conn/group/stats.${mask}.group.FWE_${task}_mask-${imask}_seed-${iseed}_${icond}"
			if [ ! -f "${f_acf}.1D" ];then
				echo -e "Perform one-sample T-test for the connectivity between $iseed and $imask in the $icond condition."
				# Perform paired T-test
				3dttest++ -setA $dir_conn/sub-*_${task}_mask-${imask}_seed-${iseed}_${icond}+tlrc.HEAD -mask $f_mask -exblur 6 -prefix $f_test -resid $f_resid
				# Estimate ACF
				3dFWHMx -ACF -mask $f_mask -input $f_resid >> ${f_acf}.1D
				mv $dir_main/scripts/3dFWHMx.1D ${f_sim}.1D
				mv $dir_main/scripts/3dFWHMx.1D.png ${f_sim}.png
				# Simulate FWE using 3dClustSim
				read -ra acf <<< $(sed '4!d' ${f_acf}.1D)
				3dClustSim -mask $f_mask -acf ${acf[0]} ${acf[1]} ${acf[2]} -athr 0.05 0.01 0.005 0.001 -prefix $f_fwe
			fi
		done
	done	
done
echo -e "========== ALL DONE! at $(date) =========="
