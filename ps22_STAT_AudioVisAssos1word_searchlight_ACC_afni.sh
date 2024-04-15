#!/bin/bash
## ---------------------------
## [script name] ps22_STAT_AudioVisAssos1word_searchlight_maps_afni.sh
## SCRIPT to ...
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
		dir_main='/data/mesocentre/data/agora/CP00'  # the project Main folder @totti
  	  	njob=4
  	  	;;
  	*)
		echo -e "Please input a valid platform!"
  	  	exit 1
esac
# Setup path
dir_data="$dir_main/AudioVisAsso"              # experiment Data folder (BIDS put into fMRIPrep)
dir_mask="$dir_data/derivatives/masks"         # masks folder
dir_mvpa="$dir_data/derivatives/multivariate"  # MVPA output folder
dir_resl="$dir_mvpa/group"                     # group results folder
# Processing parameters
readarray subjects < $dir_main/CP00_subjects.txt
task='task-AudioVisAssos1word'                    # task name
spac='space-MNI152NLin2009cAsym'                  # anatomical template that used for preprocessing by fMRIPrep
#mask="$dir_mask/group/group_${spac}_mask-gm0.2_res-${task}.nii.gz"
mask="$dir_mask/group/group_${spac}_mask-gm-lVP.nii.gz"
#mask="$dir_mask/group/group_${spac}_mask-gm-AAL3-MultimodalLanguage.nii.gz"
clfs=("LDA" "QDA" "KNN" "GNB" "SVClin" "SVCrbf")              # classifier tokens
base_acc=0.5                                      # the chance level i.e. 50%
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## Group T-tests on ACC maps
for clf in ${clfs[@]};do
	echo -e "Carry out T-tests for classifier $clf within ROI $mask."
  	## Calculate the average for cross-modal maps of LOROCV
  	#for subj in ${subjects[@]};do
	#	dir_subj="$dir_mvpa/$subj/tvsMVPC"
	#	f_AV="$dir_subj/${subj}_tvsMVPC-${clf}_LOROCV_ACC-auditory2_mask-gm0.2_res-${task}.nii.gz"
	#	f_VA="$dir_subj/${subj}_tvsMVPC-${clf}_LOROCV_ACC-visual2_mask-gm0.2_res-${task}.nii.gz"
	#	if [ ! -f $f_AV ];then
	#		3dMean -prefix $f_AV $dir_subj/${subj}_tvsMVPC-${clf}_LOROCV-run*_ACC-auditory2_mask-gm0.2_res-${task}.nii.gz  # auditory-to-visual maps
  	#  		3dMean -prefix $f_VA $dir_subj/${subj}_tvsMVPC-${clf}_LOROCV-run*_ACC-visual2_mask-gm0.2_res-${task}.nii.gz  # visual-to-auditory maps
	#	fi
  	#done
  	## Group analysis for LOROCV
	#mods=("visual" "auditory" "visual2" "auditory2")  # decoding modality
  	#for imod in ${mods[@]};do
	#	f_acc="$dir_resl/stats.acc_group_tvsMVPC-${clf}_LOROCV_ACC-${imod}_mask-gm0.2_res-${task}.nii.gz"
  	#  	f_abv="$dir_resl/stats.acc_group_tvsMVPC-${clf}_LOROCV_ACC-above-chance-${imod}_mask-gm0.2_res-${task}.nii.gz"
	#	f_test="$dir_resl/stats.group_tvsMVPC-${clf}_LOROCV_ACC-above-chance-${imod}_mask-gm0.2_res-${task}_blur-4mm.nii.gz"
	#	if [ ! -f $f_abv ];then
	#		3dbucket -fbuc -aglueto $f_acc $dir_mvpa/sub-*/tvsMVPC/sub-*_tvsMVPC-${clf}_LOROCV_ACC-${imod}_mask-gm0.2_res-${task}.nii.gz
	#		3dcalc -a $f_acc -expr "a-$base_acc" -prefix $f_abv  # calculate above-chance ACC
	#	fi
	#	if [ ! -f $f_test ]
	#		3dttest++ -setA $f_abv -mask $mask -exblur 4 -prefix $f_test 
  	#  		#3dttest++ -singletonA $base_acc -setB $f_acc -mask $mask -exblur 6 -prefix $dir_resl/stats.group_tvsMVPC-${clf}_LOROCV_ACC-${imod}_mask-gm0.2_res-${task}_blur-6mm.nii.gz  # -singletonA doesn't work well with -exblur
	#	fi
  	#done
	# Group analysis for LOSOCV
	mods=("V" "A" "V2" "A2")  # decoding modality
	for imod in ${mods[@]};do
		f_acc="$dir_resl/stats.acc_group_gMVPA-${clf}_LOSOCV_ACC-${imod}_mask-gm0.2_res-${task}.nii.gz"
  	  	f_abv="$dir_resl/stats.acc_group_gMVPA-${clf}_LOSOCV_ACC-above-chance-${imod}_mask-gm0.2_res-${task}.nii.gz"
		if [ ! -f $f_abv ];then
			3dbucket -fbuc -aglueto $f_acc $dir_mvpa/groupMVPA/SearchlightMaps/sub-*_gMVPA-${clf}_LOSOCV_ACC-${imod}_searchlight-4mm_mask-gm0.2_res-${task}.nii.gz
			3dcalc -a $f_acc -expr "a-$base_acc" -prefix $f_abv  # calculate above-chance ACC
		fi
  	  	# T-test on one sample againest the chance level with FWE estimation: lVP, MLang
		f_test="$dir_resl/stats.lVP.group_gMVPA-${clf}_LOSOCV_ACC-above-chance-${imod}_mask-gm0.2_res-${task}"
		f_resid="$dir_resl/stats.lVP.group.resid_gMVPA-${clf}_LOSOCV_ACC-above-chance-${imod}_mask-gm0.2_res-${task}+tlrc"
		f_acf="$dir_resl/stats.lVP.group.ACF_gMVPA-${clf}_LOSOCV_ACC-above-chance-${imod}_mask-gm0.2_res-${task}"
		f_sim="$dir_resl/stats.lVP.group.ACFc_gMVPA-${clf}_LOSOCV_ACC-above-chance-${imod}_mask-gm0.2_res-${task}"
		f_fwe="$dir_resl/stats.lVP.group.FWE_gMVPA-${clf}_LOSOCV_ACC-above-chance-${imod}_mask-gm0.2_res-${task}"
		if [ ! -f "${f_acf}.1D" ];then
			echo -e "Perform one-sample T-test for the $imod decoding."
			# Perform paired T-test
			3dttest++ -setA $f_abv -mask $mask -exblur 6 -prefix $f_test -resid $f_resid
			# Estimate ACF
			3dFWHMx -ACF -mask $mask -input $f_resid >> ${f_acf}.1D
			mv $dir_main/scripts/3dFWHMx.1D ${f_sim}.1D
			mv $dir_main/scripts/3dFWHMx.1D.png ${f_sim}.png
			# Simulate FWE using 3dClustSim
			read -ra acf <<< $(sed '4!d' ${f_acf}.1D)
			3dClustSim -mask $mask -acf ${acf[0]} ${acf[1]} ${acf[2]} -athr 0.05 0.01 0.005 0.001 -prefix $f_fwe
		fi
	done
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
