#!/bin/bash
## ---------------------------
## [script name] ps07_STAT_LocaVis1p75_ttests_afni.sh
##
## SCRIPT to perform T-tests to extract individual and group-averaged VWFA and to determine the denoising strategy.
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
task='task-LocaVis1p75'           # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
mask="$kdir/group/group_${spac}_mask-gm-final_res-${task}.nii.gz"  # GM mask
models=("GLM.wNRmin" "GLM.wNR12" "GLM.wNR14" "GLM.wNR50")          # GLM with different denoising strategies
# index the stat volumes
eidx=10                  # coefficients
fidx=11                  # T values
flab='words-consonants'  # contrast label
## ---------------------------

echo -e "========== START JOB at $(date) =========="

### extract beta coefficients
#for subj in ${subjects[@]};do
#  echo -e "extract beta maps for $task for subject : $subj ......"
#  wdir="$adir/$subj/$task"
#  # specify stat files
#  for model in ${models[@]};do
#    oglm="${subj}_${task}_${model}"
#    stat="$wdir/$oglm/stats.${subj}_${task}+tlrc.HEAD"
#    coef="$wdir/$oglm/stats.beta_${oglm}_${flab}.nii.gz"
#    # extract coef maps for group analysis
#    if [ ! -f $coef ];then
#      3dbucket -fbuc -prefix $coef "${stat}[$eidx]"
#    fi
#  done
#done
### ---------------------------

## group T-tests
tdir="$adir/group/$task"
if [ ! -d $tdir ];then mkdir -p $tdir;fi
for model in ${models[@]};do
#  # stack up subjects for group analysis
#  3dbucket -fbuc -aglueto $tdir/stats.beta_group_${task}_${model}_${flab}.nii.gz \
#    $adir/sub-*/$task/sub-*_${task}_${model}/stats.beta_sub-*_${flab}.nii.gz
  # T-test
  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_${flab}.nii.gz -mask $mask -exblur 4 -prefix $tdir/stats.group_${task}_${model}_${flab}
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
