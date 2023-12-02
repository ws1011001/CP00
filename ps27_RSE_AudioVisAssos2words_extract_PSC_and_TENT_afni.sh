#!/bin/bash
## ---------------------------
## [script name] ps27_RSE_AudioVisAssos2words_extract_PSC_and_TENT_afni.sh
## SCRIPT to ...
##
## By Shuai Wang
## ---------------------------

## Set environment (packages, functions, working path etc.)
# Platform
platform='local'
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
dir_data="$dir_main/AudioVisAsso"                # experiment Data folder (BIDS put into fMRIPrep)
dir_afni="$dir_data/derivatives/afni"            # AFNI output folder
dir_mask="$dir_data/derivatives/masks"
# Processing parameters
readarray subjects < $dir_main/CP00_subjects.txt
readarray rois < $dir_afni/group_masks_labels-RSE.txt
task='task-AudioVisAssos2words'   # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
deno='NR24a'                      # denoising strategy
cons=("SISMa" "SISMv" "SIDMa" "SIDMv" "DISMa" "DISMv" "DIDMa" "DIDMv" "catch")
## ---------------------------

## Extract PSC and TENT
f_psc="$dir_afni/group_${task}_RSE_PSC+TENT.csv"
echo "participant_id,ROI_label,condition,PSC,IRF1,IRF2,IRF3,IRF4,IRF5,IRF6,IRF7,IRF8,IRF9" >> $f_psc
for subj in ${subjects[@]};do
	echo -e "extract PSC and TENT curves for $task for subject : $subj ......"
  	dir_task="$dir_afni/$subj/$task"                       # the Working folder
  	oglm="${subj}_${task}_GLM.wBIM.wPSC.w${deno}"  # the token for the Output GLM
  	tent="${subj}_${task}_GLM.wBIM.wPSC.wTENT.w${deno}"  # the token for the Output GLM
  	# Extract PSC and TENT for each ROI 
  	f_glm="$dir_task/$oglm/stats.${subj}_${task}+tlrc."
  	for iroi in ${rois[@]};do
		if [ "${iroi::1}" = 'i' ];then
			f_roi="$dir_mask/$subj/${subj}_${spac}_mask-${iroi}.nii.gz"
  	  	else
			f_roi="$dir_mask/group/group_${spac}_mask-${iroi}.nii.gz"
  	  	fi
  	  	i=1
  	  	for icon in ${cons[@]};do
			f_irf="$dir_task/$tent/TENT_IRF_${icon}.${subj}_${task}+tlrc."
  	  	  	x=$(3dmaskave -q -mask $f_roi ${f_glm}[$i])
  	  	  	readarray t <<< $(3dmaskave -q -mask $f_roi $f_irf)
  	  	  	echo -e "$subj,$iroi,$icon,$x,${t[0]%$'\n'},${t[1]%$'\n'},${t[2]%$'\n'},${t[3]%$'\n'},${t[4]%$'\n'},${t[5]%$'\n'},${t[6]%$'\n'},${t[7]%$'\n'},${t[8]%$'\n'}" >> $f_psc
  	  	  	let i+=3
  	  	done
  	done
done
## ---------------------------
