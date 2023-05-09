#!/bin/bash
## ---------------------------
## [script name] ps17_STAT_AudioVisAssos1word_factorial_afni.sh
## SCRIPT to perform factorial tests (i.e. 3dMVM) to get group results.
##
## By Shuai Wang, [date] 2021-06-30
## ---------------------------
## Notes:
## ---------------------------

## Set environment (packages, functions, working path etc.)
# Platform
platform='mesoc'
case "$platform" in
	mesoc)
		dir_main='/CP00'                       # the project Main folder @mesocentre
  	  	export PATH="$dir_main/nitools:$PATH"  # setup tools if @mesocentre
  	  	njob=8
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
dir_data="$dir_main/AudioVisAsso"       # experiment Data folder (BIDS put into fMRIPrep)
dir_afni="$dir_data/derivatives/afni"   # AFNI output folder
dir_mask="$dir_data/derivatives/masks"  # masks folder
# processing parameters
readarray subjects < $dir_main/CP00_subjects.txt
readarray rois < $dir_afni/group_masks_labels-AVA.txt
task='task-AudioVisAssos1word'    # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
mask="$dir_mask/group/group_${spac}_mask-gm-0.2_res-${task}.nii.gz"  # GM mask
models=("GLM.wBIM.wPSC.wNR24a")
# index the stat volumes
eidx=(1 4 7 10)
flab=("WA" "WV" "PA" "PV")
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## Group MVM
dir_task="$dir_afni/group/$task"
if [ ! -d $dir_task ];then mdir_mask -p $dir_task;fi
for model in ${models[@]};do
	f_table="$dir_task/stats.group_${task}_${model}_MVM.dataTable"
  	# Generate the datatable for 3dMVM
  	if [ ! -f "$f_table" ];then
		echo "Subj Modality Lexicon InputFile" >> $f_table
  	  	for subj in ${subjects[@]};do 
			dir_stat="$dir_afni/$subj/${task}/${subj}_${task}_${model}"
  	  	  	echo "$subj A W $dir_stat/stats.${subj}_${task}+tlrc.[WA_cor#0_Coef]" >> $f_table
  	  	  	echo "$subj A P $dir_stat/stats.${subj}_${task}+tlrc.[PA_cor#0_Coef]" >> $f_table
  	  	  	echo "$subj V W $dir_stat/stats.${subj}_${task}+tlrc.[WV_cor#0_Coef]" >> $f_table
  	  	  	echo "$subj V P $dir_stat/stats.${subj}_${task}+tlrc.[PV_cor#0_Coef]" >> $f_table
  	  	done
  	fi
  	# Perform MVM
  	f_mvm="$dir_task/stats.group_${task}_${model}_MVM"
  	if [ ! -f "${f_mvm}+tlrc.HEAD" ];then
		echo -e "Do MVM for the $task with $model. "
  	  	3dMVM -prefix $f_mvm \
			-jobs $njob \
  	  	  	-bsVars 1 \
  	  	  	-wsVars "Modality*Lexicon" \
  	  	  	-SS_type 3 \
  	  	  	-num_glt 14 \
  	  	  	-gltLabel 1 Full_Aud -gltCode 1 'Modality : 1*A' \
  	  	  	-gltLabel 2 Full_Vis -gltCode 2 'Modality : 1*V' \
  	  	  	-gltLabel 3 Full_Aud-Vis -gltCode 3 'Modality : 1*A -1*V' \
  	  	  	-gltLabel 4 Full_Word -gltCode 4 'Lexicon : 1*W' \
  	  	  	-gltLabel 5 Full_Pseu -gltCode 5 'Lexicon : 1*P' \
  	  	  	-gltLabel 6 Full_Word-Pseu -gltCode 6 'Lexicon : 1*W -1*P' \
  	  	  	-gltLabel 7 Word_Aud -gltCode 7 'Modality : 1*A Lexicon : 1*W' \
  	  	  	-gltLabel 8 Word_Vis -gltCode 8 'Modality : 1*V Lexicon : 1*W' \
  	  	  	-gltLabel 9 Pseu_Aud -gltCode 9 'Modality : 1*A Lexicon : 1*P' \
  	  	  	-gltLabel 10 Pseu_Vis -gltCode 10 'Modality : 1*V Lexicon : 1*P' \
  	  	  	-gltLabel 11 Word_Aud-Vis -gltCode 11 'Modality : 1*A -1*V Lexicon : 1*W' \
  	  	  	-gltLabel 12 Pseu_Aud-Vis -gltCode 12 'Modality : 1*A -1*V Lexicon : 1*P' \
  	  	  	-gltLabel 13 Aud_Word-Pseu -gltCode 13 'Modality : 1*A Lexicon : 1*W -1*P' \
  	  	  	-gltLabel 14 Vis_Word-Pseu -gltCode 14 'Modality : 1*V Lexicon : 1*W -1*P' \
  	  	  	-dataTable @$f_table
  	fi
done
## ---------------------------

### Extract beta coefficients
#for subj in ${subjects[@]};do
#	echo -e "Extract beta maps for the $task for $subj. "
#  	dir_subj="$dir_afni/$subj/$task"
#  	# Specify stat files
#  	for model in ${models[@]};do
#		oglm="${subj}_${task}_${model}"
#  	  	stat="$dir_subj/$oglm/stats.${subj}_${task}+tlrc.HEAD"
#  	  	# Extract coef maps for group analysis
#  	  	i=0
#  	  	for ilab in ${flab[@]};do
#			coef="$dir_subj/$oglm/stats.beta_${oglm}_${ilab}.nii.gz"
#  	  	  	if [ ! -f $coef ];then
#				3dbucket -fbuc -prefix $coef "${stat}[${eidx[i]}]"
#  	  	  	fi
#  	  	  	let i+=1
#  	  	done
#  	done
#done
### ---------------------------
#
### Extract PSC for ROI analysis
#model='GLM.wBIM.wPSC.wNR24a'
#f_psc="$dir_afni/group_${task}_${model}_PSC.csv"
#echo "participant_id,ROI_label,condition,PSC" >> $f_psc
#rads=(4 5 6 7 8)  # radii used for individual left-vOT ROIs
#for subj in ${subjects[@]};do
#	echo -e "Extract beta values (PSC) with ROIs for the $task for subject $subj."
#  	dir_subj="$dir_afni/$subj/$task"
#  	oglm="${subj}_${task}_${model}"
#  	# Specify PSC beta files
#  	for ilab in ${flab[@]};do
#		f_coef="$dir_subj/$oglm/stats.beta_${oglm}_${ilab}.nii.gz"
#  	  	# Extract PSC data for group ROIs
#  	  	for iroi in ${rois[@]};do
#			f_roi="$dir_mask/group/group_${spac}_mask-${iroi}.nii.gz"
#  	  	  	psc=$(3dBrickStat -mean -mask $f_roi $f_coef)
#			echo -e "$subj,$iroi,$ilab,$psc" >> $f_psc
#  	  	done
#  	  	# Extract PSC beta for individual ROIs
#  	  	for srad in ${rads[@]};do
#			f_roi="$dir_mask/$subj/${subj}_${spac}_mask-ilvOT-sph${srad}mm.nii.gz"
#  	  	  	psc=$(3dBrickStat -mean -mask $f_roi $f_coef)
#  	  	  	echo -e "$subj,ilvOT-sph${srad}mm,$ilab,$psc" >> $f_psc
#  	  	done
#  	done
#done
### ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
