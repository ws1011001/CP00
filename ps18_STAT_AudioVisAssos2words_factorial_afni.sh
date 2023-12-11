#!/bin/bash
## ---------------------------
## [script name] ps15_STAT_LocaAudio2p5_ttests_afni.sh
## SCRIPT to perform T-tests to extract group results and to determine the denoising strategy.
##
## By Shuai Wang, [date] 2021-01-27
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
  	  	njob=16
  	  	;;
  	local)
		dir_main='/data/mesocentre/data/agora/CP00'  # the project Main folder @totti
  	  	njob=8
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
task='task-AudioVisAssos2words'   # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
#mask="$dir_mask/group/group_${spac}_mask-gm0.2_res-${task}.nii.gz"  # GM mask
#mask="$dir_mask/group/group_${spac}_mask-lvOT-visual.nii.gz"  # left-vOT mask
mask="$dir_mask/group/group_${spac}_mask-gm-left-ventral-pathway.nii.gz"
models=("GLM.wBIM.wPSC.wNR24a")
conditions=("SISMa" "SISMv" "SIDMa" "SIDMv" "DISMa" "DISMv" "DIDMa" "DIDMv") # contrast labels
contrasts=("DISMv-SISMv" "DISMa-SISMa" "DIDMv-SIDMv" "DIDMa-SIDMa")
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## Extract beta coefficients
for subj in ${subjects[@]};do
	echo -e "Extract beta maps of $task for $subj. "
  	dir_task="$dir_afni/$subj/$task"
  	# Specify stat files
  	for model in ${models[@]};do
		oglm="${subj}_${task}_${model}"
  	  	f_stat="$dir_task/$oglm/stats.${subj}_${task}+tlrc.HEAD"
  	  	# Extract coef maps for group analysis
  	  	for cond in ${conditions[@]};do
			this_cond="${cond}#0_Coef"
			f_coef="$dir_task/$oglm/stats.beta_${oglm}_${cond}.nii.gz"
  	  	  	if [ ! -f $f_coef ];then
				3dbucket -fbuc -prefix $f_coef $f_stat[$this_cond]
  	  	  	fi
  	  	done
  	done
done
## ---------------------------

## Group T-tests
dir_task="$dir_afni/group/$task"
if [ ! -d $dir_task ];then mkdir -p $dir_task;fi
for model in ${models[@]};do
	for cond in ${conditions[@]};do
		# Stack up subjects for group analysis
  		f_coef="$dir_task/stats.beta_group_${task}_${model}_${cond}.nii.gz"
  		if [ ! -f $f_coef ];then
			3dbucket -fbuc -aglueto $f_coef $dir_afni/sub-*/$task/sub-*_${task}_${model}/stats.beta_sub-*_${task}_${model}_${cond}.nii.gz
  		fi
	done
  	# Between-condition T-test with FWE estimation
	for cont in ${contrasts[@]};do
		cond_pair=(${cont//-/ })
		f_con1="$dir_task/stats.beta_group_${task}_${model}_${cond_pair[0]}.nii.gz"
		f_con2="$dir_task/stats.beta_group_${task}_${model}_${cond_pair[1]}.nii.gz"
		f_test="$dir_task/stats.lVP.group_${task}_${model}_TTest_${cont}"
		f_resid="$dir_task/stats.lVP.group.resid_${task}_${model}_TTest_${cont}+tlrc"
		f_acf="$dir_task/stats.lVP.group.ACF_${task}_${model}_TTest_${cont}"
		f_sim="$dir_task/stats.lVP.group.ACFc_${task}_${model}_TTest_${cont}"
		f_fwe="$dir_task/stats.lVP.group.FWE_${task}_${model}_TTest_${cont}"
		if [ ! -f "${f_acf}.1D" ];then
			echo -e "Perform paired T-test for the contrast ${cond_pair[0]} vs. ${cond_pair[1]}."
			# Perform paired T-test
			3dttest++ -setA $f_con1 -setB $f_con2 -mask $mask -exblur 6 -paired -prefix $f_test -resid $f_resid
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
