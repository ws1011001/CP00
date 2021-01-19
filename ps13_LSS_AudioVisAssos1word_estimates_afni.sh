#!/bin/bash
## ---------------------------
## [script name] ps13_LSS_AudioVisAssos1word_estimates_afni.sh
##
## SCRIPT to ...
##
## By Shuai Wang, [date] 2020-10-20
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
adir="$ddir/derivatives/afni"          # AFNI output folder
vdir="$ddir/derivatives/multivariate"  # MVPA working folder
# processing parameters
readarray subjects < $mdir/CP00_subjects.txt
task='task-AudioVisAssos1word'        # task name
deno='NR14'                           # denoising strategy
cons=("WA" "WV" "PA" "PV")            # conditions
## ---------------------------

## run GLM for each subject
for subj in ${subjects[@]};do
  echo -e "extract betas from LSS for $task for subject : $subj ......"

  wdir="$adir/$subj/$task"                  # the task folder
  oglm="${subj}_${task}_GLM.wPSC.w${deno}"  # scaled model token
  tdir="$wdir/$oglm/trial-wise_estimates"   # LSS results folder
  sdir="$vdir/$subj"                        # multivariate subject folder
  
  # create subject folder
  if [ ! -d "$sdir/betas_afni" ];then
    mkdir -p $sdir/betas_afni
  fi
  
  # prepare trial-wise estimates for multivariate analyses
  i=1
  for icon in ${cons[@]};do
    cprefix=`printf "con%d" $i`
    ConvertAFNItoNIFTI $tdir/LSS.stats.${subj}_${task}_${cprefix}_${icon}+tlrc $sdir/betas_afni ${cprefix}_trl
    let i+=1
  done
  
  # prepare trial-wise estimates for nilearn
  echo -e "Prepare LSS estimates of subject: $subj for MVPA......"
  3dbucket -fbuc -aglueto $sdir/betas_afni/${subj}_LSS.nii.gz $sdir/betas_afni/con*.nii
  3dTcat -prefix $sdir/betas_afni/${subj}_LSS_nilearn.nii.gz $sdir/betas_afni/${subj}_LSS.nii.gz
  echo -e "The data preparation for MVPA for subject: $subj is done!"
done
## ---------------------------
