#!/bin/bash
## ---------------------------
## [script name] ps34_STAT_extract_gradients_lVP.sh
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
		dir_main='/data/mesocentre/data/agora/CP00'  # the project Main folder @totti
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
n_subjects=${#subjects[@]}
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
mask="$dir_mask/group/group_${spac}_mask-gm-lVP.nii.gz"
tasks=("task-LocaVis1p75" "task-LocaAudio2p5" "task-AudioVisAssos1word" "task-AudioVisAssos2words")
tasks=("task-AudioVisAssos1word" "task-AudioVisAssos2words")
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## task-LocaVis1p75
task='task-LocaVis1p75'
model='GLM.wBIM.wPSC.wNR24a'
dir_task="$dir_afni/group/$task"
f_stat="$dir_task/stats.group_${task}_${model}_paired2-words-consonants+tlrc."
f_mean="$dir_task/grads.lVP.group_${task}_${model}_paired2-words-consonants.tsv"
f_beta="$dir_task/stats.beta_group_${task}_${model}_words-consonants.nii.gz"
f_grad=""
# Extract group average
if [ ! -f $f_mean ];then
	3dGradCurve -i $f_stat[0] -k $mask -r 1 -a -9 -p -107 -o $f_mean
fi
# Extract each individual
#for i in $(seq 1 $n_subjects);do
#	let idx=$i-1
#	f_temp="$dir_task/grad_temp$(printf '%02d' $i).tsv"
#	3dGradCurve -i $f_beta[$idx] -k $mask -r 1 -a -9 -p -107 -o $f_temp
#done
## ---------------------------



echo -e "========== ALL DONE! at $(date) =========="
