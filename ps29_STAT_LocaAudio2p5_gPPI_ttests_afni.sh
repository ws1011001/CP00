#!/bin/bash
## ---------------------------
## [script name] ps29_STAT_LocaAudio2p5_gPPI_ttests_afni.sh
## SCRIPT to perform T-tests to extract group results of gPPI.
##
## By Shuai Wang, [date] 2022
## ---------------------------
## Notes:
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
readarray seeds < $adir/group_masks_labels-gPPI.txt  # seed regions for gPPI
task='task-LocaAudio2p5'          # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
mask="$kdir/group/group_${spac}_mask-gm0.2_res-${task}.nii.gz"  # GM mask
lvot="$kdir/group/group_${spac}_mask-lvOT-visual-res.nii.gz"    # lvOT mask
model='GLM.wPSC.wNR24a.gPPI'
# index the stat volumes
eidx=(13 16 19)  # coefficients
flab=("words" "pseudowords" "scrambled")
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## extract beta coefficients
for subj in ${subjects[@]};do
  echo -e "extract beta maps for $task for subject : $subj ......"
  wdir="$adir/$subj/$task"
  # specify stat files
  for seed in ${seeds[@]};do
    pglm="${subj}_${task}_${model}"
    stat="$wdir/$pglm/$seed/stats.${subj}_${task}+tlrc.HEAD"
    # extract coef maps for group analysis
    i=0
    for ilab in ${flab[@]};do
      coef="$wdir/$pglm/$seed/stats.beta_${pglm}_seed-${seed}_${ilab}.nii.gz"
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
for seed in ${seeds[@]};do
  for ilab in ${flab[@]};do
    # stack up subjects for group analysis
    gcoef="$tdir/stats.beta_group_${task}_${model}_seed-${seed}_${ilab}.nii.gz"
    if [ ! -f $gcoef ];then
      3dbucket -fbuc -aglueto $gcoef $adir/sub-*/$task/sub-*_${task}_${model}/$seed/stats.beta_sub-*_${ilab}.nii.gz
    fi
  done  
  # T-test on paried two samples
  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_seed-${seed}_words.nii.gz \
    -setB $tdir/stats.beta_group_${task}_${model}_seed-${seed}_pseudowords.nii.gz \
    -mask $mask -exblur 5 -paired \
    -prefix $tdir/stats.group_${task}_${model}_seed-${seed}_words-pseudowords.nii.gz
  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_seed-${seed}_words.nii.gz \
    -setB $tdir/stats.beta_group_${task}_${model}_seed-${seed}_scrambled.nii.gz \
    -mask $mask -exblur 5 -paired \
    -prefix $tdir/stats.group_${task}_${model}_seed-${seed}_words-scrambled.nii.gz
  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_seed-${seed}_pseudowords.nii.gz \
    -setB $tdir/stats.beta_group_${task}_${model}_seed-${seed}_scrambled.nii.gz \
    -mask $mask -exblur 5 -paired \
    -prefix $tdir/stats.group_${task}_${model}_seed-${seed}_pseudowords-scrambled.nii.gz
  # T-test on paried two samples within the left-vOT mask
  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_seed-${seed}_words.nii.gz \
    -setB $tdir/stats.beta_group_${task}_${model}_seed-${seed}_pseudowords.nii.gz \
    -mask $lvot -exblur 5 -paired \
    -prefix $tdir/stats.lvOT.group_${task}_${model}_seed-${seed}_words-pseudowords.nii.gz
  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_seed-${seed}_words.nii.gz \
    -setB $tdir/stats.beta_group_${task}_${model}_seed-${seed}_scrambled.nii.gz \
    -mask $lvot -exblur 5 -paired \
    -prefix $tdir/stats.lvOT.group_${task}_${model}_seed-${seed}_words-scrambled.nii.gz
  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_seed-${seed}_pseudowords.nii.gz \
    -setB $tdir/stats.beta_group_${task}_${model}_seed-${seed}_scrambled.nii.gz \
    -mask $lvot -exblur 5 -paired \
    -prefix $tdir/stats.lvOT.group_${task}_${model}_seed-${seed}_pseudowords-scrambled.nii.gz
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
