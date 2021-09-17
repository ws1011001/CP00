#!/bin/bash
## ---------------------------
## [script name] ps26_STAT_AudioVisAssos1word_searchlight_RSA_afni.sh
##
## SCRIPT to ...
##
## By Shuai Wang, [date] 2021-08-23
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
ddir="$mdir/AudioVisAsso"              # experiment Data folder (BIDS put into fMRIPrep)
kdir="$ddir/derivatives/masks"         # masks folder
vdir="$ddir/derivatives/multivariate"  # MVPA output folder
gdir="$vdir/group"                     # group results folder
# processing parameters
readarray subjects < $mdir/CP00_subjects.txt
task='task-AudioVisAssos1word'    # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
rsas='tvsRSA'                     # RSA methods
rois=("bvOT-Bouhali2019")         # anatomical defined left-vOT mask (Bouhali et al., 2019)
# RSA models
mods=("amodal-lexico" "amodal-lexipw" "amodal-lexiwd" 
      "audmod-lexico" "audmod-lexipw" "audmod-lexiwd" "audmod-nolexi" 
      "mmodal-lexico" "mmodal-lexipw" "mmodal-lexiwd" "mmodal-nolexi" 
      "vismod-lexico" "vismod-lexipw" "vismod-lexiwd" "vismod-nolexi")
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## group T-tests
for roi in ${rois[@]};do
  mask="$kdir/group/group_${spac}_mask-${roi}.nii.gz"
  for clf in ${clfs[@]};do
    echo -e "carry out T-tests for classifier $clf within ROI $roi ......"
    # stack up subjects for group analysis
    for imod in ${mods[@]};do
      frsa="$gdir/stats.rsa_group_${rsas}_Fisher-z_model-${imod}_mask-${roi}.nii.gz"
      3dbucket -fbuc -aglueto $frsa $vdir/sub-*/$rsas/sub-*_searchlight-rMap_model-${imod}_mask-${roi}.nii.gz
      # T-test on one sample againest the chance level
      3dttest++ -setA $frsa -mask $mask -prefix $gdir/stats.group_${rsas}_Fisher-z_model-${imod}_mask-${roi}.nii.gz
    done
  done
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
