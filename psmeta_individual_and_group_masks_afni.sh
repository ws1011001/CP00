#!/bin/bash
## ---------------------------
## [script name] psmeta_individual_and_group_masks.sh
##
## SCRIPT to ...
##
## By Shuai Wang, [date] 2021-01-20
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
ddir="$mdir/AudioVisAsso"          # experiment Data folder (BIDS put into fMRIPrep)
pdir="$ddir/derivatives/fmriprep"  # fMRIPrep output folder
adir="$ddir/derivatives/afni"      # AFNI output folder
kdir="$ddir/derivatives/masks"     # masks folder
# processing parameters
readarray subjects < $mdir/CP00_subjects.txt
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
bold='desc-preproc_bold'          # the token for the preprocessed BOLD data (without smoothing)
regs='desc-confounds_timeseries'  # the token for fMRIPrep output nuisance regressors
anat='desc-preproc_T1w_brain'     # skull-stripped anatomical image
deno='NR14'                       # denoising strategy
gmth=0.2                          # gray matter threshold between [0 1]
tasks=("task-LocaVis1p75" "task-LocaAudio2p5" "task-AudioVisAssos1word")
## ---------------------------

echo -e "========== START JOB at $(date) =========="

### create masks for each subject
#for subj in ${subjects[@]};do
#  gdir="$pdir/$subj/anat"  # individual folder that contains anatomical segments
#  sdir="$kdir/$subj"       # individual masks folder
#  if [ ! -d $sdir ];then mkdir -p $sdir;fi
#  # prepare anatomical images
#  gm_segment="$gdir/${subj}_${spac}_label-GM_probseg.nii.gz"         # gray matter segment in probability 
#  gm_mask_t1="$sdir/${subj}_${spac}_mask-gm${gmth}_res-anat.nii.gz"  # gray matter mask in T1 resolution
#  cp -r $gm_segment $sdir  # copy gray matter image to individual masks folder
#  # create individual gray matter masks
#  3dcalc -a $gm_segment -expr "ispositive(a-$gmth)" -prefix $gm_mask_t1
#  # create functional masks and functionally constrained gray matter masks
#  for task in ${tasks[@]};do
#    wdir="$adir/$subj/$task"             # the Working folder
#    oglm="${subj}_${task}_GLM.w${deno}"  # the token for the Output GLM
#    stats_afni="$wdir/$oglm/stats.${subj}_${task}+tlrc.[0]"               # AFNI statistics
#    stats_mask="$sdir/${subj}_${spac}_mask-full-F_res-${task}.nii.gz"     # functional mask based on full F statistics
#    gm_mask_bd="$sdir/${subj}_${spac}_mask-gm${gmth}_res-${task}.nii.gz"  # gray matter mask in task resolution
#    gm_fF_mask="$sdir/${subj}_${spac}_mask-gm-full-F_res-${task}.nii.gz"  # gray matter mask constrained by full F mask
#    # calculate functional mask using full F statistics
#    3dcalc -a $stats_afni -expr 'ispositive(a)' -prefix $stats_mask
#    # create functionally constrained gray matter masks
#    3dresample -master $stats_mask -prefix $gm_mask_bd -input $gm_mask_t1
#    3dcalc -a $gm_mask_bd -b $stats_mask -expr 'a*b' -prefix $gm_fF_mask
#  done
#done
### ---------------------------
#
### create group-averaged masks
#if [ ! -d "$kdir/group" ];then
#  mkdir -p $kdir/group
#fi
## gray matter mask
#3dbucket -fbuc -aglueto $kdir/group/group_${spac}_label-GM_probseg.nii.gz $kdir/sub-*/sub-*_${spac}_label-GM_probseg.nii.gz
#3dTstat -prefix $kdir/group/group_${spac}_label-GM_probseg-mean.nii.gz -mean $kdir/group/group_${spac}_label-GM_probseg.nii.gz
#3dcalc -a $kdir/group/group_${spac}_label-GM_probseg-mean.nii.gz -expr "ispositive(a-$gmth)" \
#  -prefix $kdir/group/group_${spac}_mask-gm${gmth}_res-anat.nii.gz
# functional mask (i.e. full F) and functionally constrained gray matter mask
for task in ${tasks[@]};do
  3dmask_tool -input $kdir/sub-*/sub-*_${spac}_mask-full-F_res-${task}.nii.gz \
    -prefix $kdir/group/group_${spac}_mask-full-F_res-${task}.nii.gz -frac 1.0
  3dresample -master $kdir/group/group_${spac}_mask-full-F_res-${task}.nii.gz \
    -prefix $kdir/group/group_${spac}_mask-gm${gmth}_res-${task}.nii.gz \
    -input $kdir/group/group_${spac}_mask-gm${gmth}_res-anat.nii.gz
  3dcalc -a $kdir/group/group_${spac}_mask-gm${gmth}_res-${task}.nii.gz \
    -b $kdir/group/group_${spac}_mask-full-F_res-${task}.nii.gz -expr 'a*b' \
    -prefix $kdir/group/group_${spac}_mask-gm-full-F_res-${task}.nii.gz
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
