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
readarray rois < $adir/group_masks_labels-AVA.txt
task='task-AudioVisAssos1word'    # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
mask="$kdir/group/group_${spac}_mask-gm-0.2_res-${task}.nii.gz"  # GM mask
models=("GLM.wBIM.wPSC.wNR24a")
# index the stat volumes
eidx=(1 4 7 10)
flab=("WA" "WV" "PA" "PV")
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## group MVM
tdir="$adir/group/$task"
if [ ! -d $tdir ];then mkdir -p $tdir;fi
for model in ${models[@]};do
  ftab="$tdir/stats.group_${task}_${model}_MVM.dataTable"
  # generate the datatable for 3dMVM
  if [ ! -f "$ftab" ];then
    echo "Subj modality lexicon InputFile" >> $ftab
    for subj in ${subjects[@]};do 
      sdir="$adir/$subj/${task}/${subj}_${task}_${model}"
      echo "$subj auditory word $sdir/stats.${subj}_${task}+tlrc.[WA#0_Coef]" >> $ftab
      echo "$subj auditory pseudoword $sdir/stats.${subj}_${task}+tlrc.[PA#0_Coef]" >> $ftab
      echo "$subj visual word $sdir/stats.${subj}_${task}+tlrc.[WV#0_Coef]" >> $ftab
      echo "$subj visual pseudoword $sdir/stats.${subj}_${task}+tlrc.[PV#0_Coef]" >> $ftab
    done
  fi
  # perform MVM
  fmvm="$tdir/stats.group_${task}_${model}_MVM"
  if [ ! -f "${fmvm}+tlrc.HEAD" ];then
    echo -e "Do MVM for the $task with $model. "
    3dMVM -prefix $fmvm \
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
  fi
done
## ---------------------------

## extract beta coefficients
for subj in ${subjects[@]};do
  echo -e "Extract beta maps for the $task for $subj. "
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

## Extract PSC for ROI analysis
model='GLM.wBIM.wPSC.wNR24a'
fpsc="$adir/group_${task}_${model}_PSC.csv"
echo "participant_id,ROI_label,condition,PSC" >> $fpsc
rads=(4 5 6 7 8)  # radii used for individual left-vOT ROIs
for subj in ${subjects[@]};do
  echo -e "Extract beta values (PSC) with ROIs for the $task for subject $subj."
  wdir="$adir/$subj/$task"
  oglm="${subj}_${task}_${model}"
  # specify PSC beta files
  for ilab in ${flab[@]};do
    coef="$wdir/$oglm/stats.beta_${oglm}_${ilab}.nii.gz"
    # extract PSC data for group ROIs
    for iroi in ${rois[@]};do
      froi="$kdir/group/group_${spac}_mask-${iroi}.nii.gz"
      psc=$(3dBrickStat -mean -mask $froi $coef)
      echo -e "$subj,$iroi,$ilab,$psc" >> $fpsc
    done
    # extract PSC beta for individual ROIs
    for srad in ${rads[@]};do
      froi="$kdir/$subj/${subj}_${spac}_mask-ilvOT-sph${srad}mm.nii.gz"
      psc=$(3dBrickStat -mean -mask $froi $coef)
      echo -e "$subj,ilvOT-sph${srad}mm,$ilab,$psc" >> $fpsc
    done
  done
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
