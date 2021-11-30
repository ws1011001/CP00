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
    njob=4
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
task='task-LocaAudio2p5'          # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
mask="$kdir/group/group_${spac}_mask-gm0.2_res-${task}.nii.gz"  # GM mask
models=("GLM.wPSC.wNR24a")
# index the stat volumes
eidx=(13 16 19)  # coefficients
fidx=(14 17 20)  # T values
flab=("words-pseudowords" "words-scrambled" "pseudowords-scrambled")  # contrast labels
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## extract beta coefficients
for subj in ${subjects[@]};do
  echo -e "extract beta maps for $task for subject : $subj ......"
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

## group T-tests
tdir="$adir/group/$task"
if [ ! -d $tdir ];then mkdir -p $tdir;fi
for model in ${models[@]};do
  for ilab in ${flab[@]};do
    # stack up subjects for group analysis
    gcoef="$tdir/stats.beta_group_${task}_${model}_${ilab}.nii.gz"
    if [ ! -f $gcoef ];then
      3dbucket -fbuc -aglueto $gcoef $adir/sub-*/$task/sub-*_${task}_${model}/stats.beta_sub-*_${ilab}.nii.gz
    fi
    # T-test
    3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_${ilab}.nii.gz -mask $mask -exblur 6 -prefix $tdir/stats.group_${task}_${model}_${ilab}
  done  
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
