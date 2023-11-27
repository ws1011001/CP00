#!/bin/bash
## ---------------------------
## [script name] ps22_STAT_AudioVisAssos1word_searchlight_maps_afni.sh
## SCRIPT to ...
##
## By Shuai Wang
## ---------------------------

## set environment (packages, functions, working path etc.)
# platform
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
# setup path
dir_data="$dir_main/AudioVisAsso"              # experiment Data folder (BIDS put into fMRIPrep)
dir_mask="$dir_data/derivatives/masks"         # masks folder
dir_mvpa="$dir_data/derivatives/multivariate"  # MVPA output folder
dir_resl="$dir_mvpa/group"                     # group results folder
# processing parameters
readarray subjects < $dir_main/CP00_subjects.txt
task='task-AudioVisAssos1word'                    # task name
spac='space-MNI152NLin2009cAsym'                  # anatomical template that used for preprocessing by fMRIPrep
clfs=("LDA" "GNB" "SVClin" "SVCrbf")              # classifier tokens
rois=("gm0.2_res-${task}")						  # anatomical mask
mods=("visual" "auditory" "visual2" "auditory2")  # decoding modality
base_acc=0.5                                      # the chance level i.e. 50%
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## Group T-tests on ACC maps
for roi in ${rois[@]};do
	mask="$dir_mask/group/group_${spac}_mask-${roi}.nii.gz"
  	for clf in ${clfs[@]};do
		echo -e "Carry out T-tests for classifier $clf within ROI $roi."
  	  	## Calculate the average for cross-modal maps of LOROCV
  	  	#for subj in ${subjects[@]};do
		#	dir_subj="$dir_mvpa/$subj/tvsMVPC"
  	  	#  	# auditory-to-visual maps
  	  	#  	3dMean -prefix $dir_subj/${subj}_tvsMVPC-${clf}_LOROCV_ACC-auditory2_mask-${roi}.nii.gz $dir_subj/${subj}_tvsMVPC-${clf}_LOROCV-run*_ACC-auditory2_mask-${roi}.nii.gz
  	  	#  	# visual-to-auditory maps
  	  	#  	3dMean -prefix $dir_subj/${subj}_tvsMVPC-${clf}_LOROCV_ACC-visual2_mask-${roi}.nii.gz $dir_subj/${subj}_tvsMVPC-${clf}_LOROCV-run*_ACC-visual2_mask-${roi}.nii.gz
  	  	#done
  	  	## Group analysis for LOROCV
  	  	#for imod in ${mods[@]};do
		#	f_acc="$dir_resl/stats.acc_group_tvsMVPC-${clf}_LOROCV_ACC-${imod}_mask-${roi}.nii.gz"
  	  	#  	3dbucket -fbuc -aglueto $f_acc $dir_mvpa/sub-*/tvsMVPC/sub-*_tvsMVPC-${clf}_LOROCV_ACC-${imod}_mask-${roi}.nii.gz
  	  	#  	# Calculate above-chance ACC
  	  	#  	f_abv="$dir_resl/stats.acc_group_tvsMVPC-${clf}_LOROCV_ACC-above-chance-${imod}_mask-${roi}.nii.gz"
  	  	#  	3dcalc -a $f_acc -expr "a-$base_acc" -prefix $f_abv
  	  	#  	# T-test on one sample againest the chance level
  	  	#  	3dttest++ -setA $f_abv -mask $mask -exblur 4 -prefix $dir_resl/stats.group_tvsMVPC-${clf}_LOROCV_ACC-above-chance-${imod}_mask-${roi}_blur-4mm.nii.gz
  	  	#  	#3dttest++ -singletonA $base_acc -setB $f_acc -mask $mask -exblur 6 -prefix $dir_resl/stats.group_tvsMVPC-${clf}_LOROCV_ACC-${imod}_mask-${roi}_blur-6mm.nii.gz  # -singletonA doesn't work well with -exblur
  	  	#done
		# Group analysis for LOSOCV
		mods=("V" "A" "V2" "A2")
		for imod in ${mods[@]};do
			f_acc="$dir_resl/stats.acc_group_gMVPA-${clf}_LOSOCV_ACC-${imod}_mask-${roi}.nii.gz"
  	  	  	3dbucket -fbuc -aglueto $f_acc $dir_mvpa/groupMVPA/SearchlightMaps/sub-*_gMVPA-${clf}_LOSOCV_ACC-${imod}_searchlight-4mm_mask-${roi}.nii.gz
  	  	  	# Calculate above-chance ACC
  	  	  	f_abv="$dir_resl/stats.acc_group_gMVPA-${clf}_LOSOCV_ACC-above-chance-${imod}_mask-${roi}.nii.gz"
  	  	  	3dcalc -a $f_acc -expr "a-$base_acc" -prefix $f_abv
  	  	  	# T-test on one sample againest the chance level
  	  	  	3dttest++ -setA $f_abv -mask $mask -exblur 6 -prefix $dir_resl/stats.group_gMVPA-${clf}_LOSOCV_ACC-above-chance-${imod}_mask-${roi}_blur-6mm.nii.gz
		done
  	done
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
