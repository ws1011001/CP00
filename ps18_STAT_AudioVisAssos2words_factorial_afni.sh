#!/bin/bash
## ---------------------------
## [script name] ps15_STAT_LocaAudio2p5_ttests_afni.sh
##
## SCRIPT to perform T-tests to extract group results and to determine the denoising strategy.
##
## By Shuai Wang, [date] 2021-01-27
##
## ---------------------------
## Notes:
##   
##
## ---------------------------

## set environment (packages, functions, working path etc.)
# platform
platform='mesoc'
case "$platform" in
  mesoc)
    mdir='/CP00'                       # the project Main folder @mesocentre
    export PATH="$mdir/nitools:$PATH"  # setup tools if @mesocentre
    njob=16
    ;;
  totti)
    mdir='/data/mesocentre/data/agora/CP00'  # the project Main folder @totti
    njob=8
    ;;
  *)
    echo -e "Please input a valid platform!"
    exit 1
esac
# setup path
ddir="$mdir/AudioVisAsso"       # experiment Data folder (BIDS put into fMRIPrep)
adir="$ddir/derivatives/afni"   # AFNI output folder
kdir="$ddir/derivatives/masks"  # masks folder
# processing parameters
readarray subjects < $mdir/CP00_subjects.txt
task='task-AudioVisAssos2words'   # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
#mask="$kdir/group/group_${spac}_mask-gm0.2_res-${task}.nii.gz"  # GM mask
mask="$kdir/group/group_${spac}_mask-lvOT-visual.nii.gz"  # left-vOT mask
models=("GLM.wBIM.wPSC.wNR24a")
# index the stat volumes
eidx=(1 4 7 10 13 16 19 22)            # coefficients
flab=("SISMa" "SISMv" "SIDMa" "SIDMv" "DISMa" "DISMv" "DIDMa" "DIDMv") # contrast labels
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## Group MVM
## ---------------------------

## Extract beta coefficients
for subj in ${subjects[@]};do
  echo -e "Extract beta maps of $task for $subj. "
  wdir="$adir/$subj/$task"
  # specify stat files
  for model in ${models[@]};do
    oglm="${subj}_${task}_${model}"
    stat="$wdir/$oglm/stats.${subj}_${task}+tlrc.HEAD"
    # extract coef maps for group analysis
    i=0
    for ilab in ${flab[@]};do
      coef="$wdir/$oglm/stats.beta_${oglm}_${ilab}.nii.gz"
      if [ ! -f $coef ];then
        3dbucket -fbuc -prefix $coef "${stat}[${eidx[i]}]"
      fi
      let i+=1
    done
  done
done
## ---------------------------

## Group T-tests
tdir="$adir/group/$task"
if [ ! -d $tdir ];then mkdir -p $tdir;fi
for model in ${models[@]};do
	for ilab in ${flab[@]};do
		# Stack up subjects for group analysis
  		gcoef="$tdir/stats.beta_group_${task}_${model}_${ilab}.nii.gz"
  		if [ ! -f $gcoef ];then
			3dbucket -fbuc -aglueto $gcoef $adir/sub-*/$task/sub-*_${task}_${model}/stats.beta_sub-*_${task}_${model}_${ilab}.nii.gz
  		fi
	done
  	3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_DISMa.nii.gz \
		-setB $tdir/stats.beta_group_${task}_${model}_SISMa.nii.gz \
	   	-mask $mask -exblur 6 \
		-prefix $tdir/stats.lvOT.group_${task}_${model}_DISMa-SISMa.nii.gz
  	3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_DISMv.nii.gz \
		-setB $tdir/stats.beta_group_${task}_${model}_SISMv.nii.gz \
	   	-mask $mask -exblur 6 \
		-prefix $tdir/stats.lvOT.group_${task}_${model}_DISMv-SISMv.nii.gz
  	3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_DIDMa.nii.gz \
		-setB $tdir/stats.beta_group_${task}_${model}_SIDMa.nii.gz \
	   	-mask $mask -exblur 6 \
		-prefix $tdir/stats.lvOT.group_${task}_${model}_DIDMa-SIDMa.nii.gz
  	3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_DIDMv.nii.gz \
		-setB $tdir/stats.beta_group_${task}_${model}_SIDMv.nii.gz \
	   	-mask $mask -exblur 6 \
		-prefix $tdir/stats.lvOT.group_${task}_${model}_DIDMv-SIDMv.nii.gz
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
