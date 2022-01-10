#!/bin/bash
## ---------------------------
## [script name] ps27_RSE_AudioVisAssos2words_extract_PSC_and_TENT_afni.sh
##
## SCRIPT to ...
##
## By Shuai Wang, [date] 2022-01-10
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
ddir="$mdir/AudioVisAsso"                # experiment Data folder (BIDS put into fMRIPrep)
adir="$ddir/derivatives/afni"            # AFNI output folder
kdir="$ddir/derivatives/masks"
# processing parameters
readarray subjects < $mdir/CP00_subjects.txt
readarray rois < $adir/group_masks_labels-RSE.txt
task='task-AudioVisAssos2words'   # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
deno='NR24a'                      # denoising strategy
cons=("SISMa" "SISMv" "SIDMa" "SIDMv" "DISMa" "DISMv" "DIDMa" "DIDMv" "catch")
## ---------------------------

## extract PSC and TENT
fpsc="$adir/group_${task}_RSE_PSC+TENT.csv"
echo "participant_id,roi_label,condition,PSC,IRF1,IRF2,IRF3,IRF4,IRF5,ORF6,IRF7,IRF8,IRF9" >> $fpsc
for subj in ${subjects[@]};do
  echo -e "extract PSC and TENT curves for $task for subject : $subj ......"
  wdir="$adir/$subj/$task"                       # the Working folder
  oglm="${subj}_${task}_GLM.wBIM.wPSC.w${deno}"  # the token for the Output GLM
  tent="${subj}_${task}_GLM.wBIM.wPSC.wTENT.w${deno}"  # the token for the Output GLM
  # extract PSC and TENT for each ROI 
  fglm="$wdir/$oglm/stats.${subj}_${task}+tlrc."
  for iroi in ${rois[@]};do
    if [ "${iroi::1}" = 'i' ];then
      froi="$kdir/$subj/${subj}_${spac}_mask-${iroi}.nii.gz"
    else
      froi="$kdir/group/group_${spac}_mask-${iroi}.nii.gz"
    fi
    i=1
    for icon in ${cons[@]};do
      firf="$wdir/$tent/TENT_IRF_${icon}.${subj}_${task}+tlrc."
      x=$(3dmaskave -q -mask $froi ${fglm}[$i])
      readarray t <<< $(3dmaskave -q -mask $froi $firf)
      echo -e "$subj,$iroi,$icon,$x,${t[0]%$'\n'},${t[1]%$'\n'},${t[2]%$'\n'},${t[3]%$'\n'},${t[4]%$'\n'},${t[5]%$'\n'},${t[6]%$'\n'},${t[7]%$'\n'},${t[8]%$'\n'}" >> $fpsc
      let i+=3
    done
  done
done
## ---------------------------
