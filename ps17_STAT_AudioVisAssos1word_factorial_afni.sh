#!/bin/bash
## ---------------------------
## [script name] ps17_STAT_AudioVisAssos1word_factorial_afni.sh
##
## SCRIPT to perform factorial tests (i.e. 3dMVM) to get group results.
##
## By Shuai Wang, [date] 2021-06-30
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
task='AudioVisAssos1word'         # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
mask="$kdir/group/group_${spac}_mask-gm-final_res-${task}.nii.gz"  # GM mask
models=("GLM.wBIM.wPSC.wNR24a")
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## group MVM
tdir="$adir/group/$task"
if [ ! -d $tdir ];then mkdir -p $tdir;fi
for model in ${models[@]};do
  # generate the datatable for 3dMVM
  ftab="$tdir/stats.group_${task}_${model}_MVM.dataTable"
  if [ ! -f "$ftab" ];then
    echo "Subj modality lexicon InputFile" >> $ftab
    for subj in ${subjects[@]};do 
      sdir="$adir/$subj/task-${task}/${subj}_task-${task}_${model}"
      echo "$subj auditory word $sdir/stats.${subj}_task-${task}+tlrc.[WA#0_Coef]" >> $ftab
      echo "$subj auditory pseudoword $sdir/stats.${subj}_task-${task}+tlrc.[PA#0_Coef]" >> $ftab
      echo "$subj visual word $sdir/stats.${subj}_task-${task}+tlrc.[WV#0_Coef]" >> $ftab
      echo "$subj visual pseudoword $sdir/stats.${subj}_task-${task}+tlrc.[PV#0_Coef]" >> $ftab
    done
  fi
  # perform MVM
  3dMVM -prefix $tdir/stats.group_${task}_${model}_MVM \
    -jobs $njob \
    -bsVars 1 \
    -wsVars "modality*lexicon" \
    -SS_type 3 \
    -num_glt 6 \
    -gltLabel 1 auditory_vs_visual -gltCode 1 'modality : 1*auditory -1*visual' \
    -gltLabel 2 auditory_vs_visual_word -gltCode 2 'modality : 1*auditory -1*visual lexicon : 1*word' \
    -gltLabel 3 auditory_vs_visual_pseudoword -gltCode 3 'modality : 1*auditory -1*visual lexicon : 1*pseudoword' \
    -gltLabel 4 word_vs_pseudoword -gltCode 4 'lexicon : 1*word -1*pseudoword' \
    -gltLabel 5 word_vs_pseudoword_auditory -gltCode 5 'modality : 1*auditory lexicon : 1*word -1*pseudoword' \
    -gltLabel 6 word_vs_pseudoword_visual -gltCode 6 'modality : 1*visual lexicon : 1*word -1*pseudoword' \
    -dataTable @$ftab
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
