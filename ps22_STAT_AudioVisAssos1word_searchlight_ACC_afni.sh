#!/bin/bash
## ---------------------------
## [script name] ps22_STAT_AudioVisAssos1word_searchlight_maps_afni.sh
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
task='task-AudioVisAssos1word'                    # task name
spac='space-MNI152NLin2009cAsym'                  # anatomical template that used for preprocessing by fMRIPrep
mvpc='tvsMVPC'                                    # MVPA methods
clfs=("LDA" "GNB" "SVClin" "SVCrbf")              # classifier tokens
rois=("bvOT-Bouhali2019-gGM")                     # anatomical defined left-vOT mask (Bouhali et al., 2019)
mods=("visual" "auditory" "visual2" "auditory2")  # decoding modality
base_acc=0.5                                      # the chance level i.e. 50%
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## group T-tests
for roi in ${rois[@]};do
  mask="$kdir/group/group_${spac}_mask-${roi}.nii.gz"
  for clf in ${clfs[@]};do
    echo -e "carry out T-tests for classifier $clf within ROI $roi ......"
    # calculate the average for cross-modal maps
    for subj in ${subjects[@]};do
      sdir="$vdir/$subj/$mvpc"
      # auditory-to-visual maps
      3dMean -prefix $sdir/${subj}_${mvpc}-${clf}_LOROCV_ACC-auditory2_mask-${roi}.nii.gz $sdir/${subj}_${mvpc}-${clf}_LOROCV-run*_ACC-auditory2_mask-${roi}.nii.gz
      # visual-to-auditory maps
      3dMean -prefix $sdir/${subj}_${mvpc}-${clf}_LOROCV_ACC-visual2_mask-${roi}.nii.gz $sdir/${subj}_${mvpc}-${clf}_LOROCV-run*_ACC-visual2_mask-${roi}.nii.gz
    done
    # stack up subjects for group analysis
    for imod in ${mods[@]};do
      facc="$gdir/stats.acc_group_${mvpc}-${clf}_LOROCV_ACC-${imod}_mask-${roi}.nii.gz"
      3dbucket -fbuc -aglueto $facc $vdir/sub-*/$mvpc/sub-*_${mvpc}-${clf}_LOROCV_ACC-${imod}_mask-${roi}.nii.gz
      # T-test on one sample againest the chance level
      3dttest++ -singletonA $base_acc -setB $facc -mask $mask -exblur 6 -prefix $gdir/stats.group_${mvpc}-${clf}_LOROCV_ACC-${imod}_mask-${roi}_blur-6mm.nii.gz
    done
  done
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
