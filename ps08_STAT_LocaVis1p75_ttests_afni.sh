#!/bin/bash
## ---------------------------
## [script name] ps08_STAT_LocaVis1p75_ttests_afni.sh
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
readarray rois < $adir/group_masks_labels-AVA.txt
task='task-LocaVis1p75'           # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
models=("GLM.wBIM.wPSC.wNR24a" "GLM.wBIGM.wPSC.wNR24a")         # the final GLM 
mask="$kdir/group/group_${spac}_mask-gm0.2_res-${task}.nii.gz"  # GM mask
lvot="$kdir/group/group_${task}_mask-lvOT-Bouhali2019.nii.gz"   # anatomical defined left-vOT mask (Bouhali et al., 2019)
# index the stat volumes
eidx_words=1
fidx_words=2
flab_words='words'
eidx_conso=4
fidx_conso=5
flab_conso='consonants'
eidx_pairs=10                  # coefficients
fidx_pairs=11                  # T values
flab_pairs='words-consonants'  # contrast label
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
#    coef_words="$wdir/$oglm/stats.beta_${oglm}_${flab_words}.nii.gz"
#    coef_conso="$wdir/$oglm/stats.beta_${oglm}_${flab_conso}.nii.gz"
#    coef_pairs="$wdir/$oglm/stats.beta_${oglm}_${flab_pairs}.nii.gz"
#    # extract coef maps for group analysis
#    if [ ! -f "$coef_words" ];then 3dbucket -fbuc -prefix $coef_words "${stat}[$eidx_words]";fi
#    if [ ! -f "$coef_conso" ];then 3dbucket -fbuc -prefix $coef_conso "${stat}[$eidx_conso]";fi
#    if [ ! -f "$coef_pairs" ];then 3dbucket -fbuc -prefix $coef_pairs "${stat}[$eidx_pairs]";fi
#    # confine stats with group-averaged GM mask
#    stat_gm="$wdir/$oglm/stats.gm_${subj}_${task}+tlrc"
#    if [ ! -f "${stat_gm}.HEAD" ];then
#      echo -e "confine stats for $task for subject : $subj ......"
#      3dcalc -a $wdir/$oglm/stats.${subj}_${task}+tlrc. -b $mask -expr 'a*b' -prefix $stat_gm
#      3drefit -addFDR $stat_gm
#    fi
#    # confine stats with anatomial defined left-vOT mask
#    stat_lvot="$wdir/$oglm/stats.lvOT_${subj}_${task}+tlrc"
#    if [ ! -f "${stat_lvot}.HEAD" ];then
#      echo -e "confine stats for $task for subject : $subj ......"
#      3dcalc -a $wdir/$oglm/stats.${subj}_${task}+tlrc. -b $lvot -expr 'a*b' -prefix $stat_lvot
#      3drefit -addFDR $stat_lvot
#    fi
#  done
#done
### ---------------------------

### group T-tests
#tdir="$adir/group/$task"
#if [ ! -d $tdir ];then mkdir -p $tdir;fi
#for model in ${models[@]};do
#  echo -e "carry out T-tests for model : $model ......"
#  # stack up subjects for group analysis
#  gcoef_words="$tdir/stats.beta_group_${task}_${model}_${flab_words}.nii.gz"
#  gcoef_conso="$tdir/stats.beta_group_${task}_${model}_${flab_conso}.nii.gz"
#  gcoef_pairs="$tdir/stats.beta_group_${task}_${model}_${flab_pairs}.nii.gz"
#  if [ ! -f "$gcoef_words" ];then
#    3dbucket -fbuc -aglueto $gcoef_words $adir/sub-*/$task/sub-*_${task}_${model}/stats.beta_sub-*_${flab_words}.nii.gz
#  fi
#  if [ ! -f "$gcoef_conso" ];then
#    3dbucket -fbuc -aglueto $gcoef_conso $adir/sub-*/$task/sub-*_${task}_${model}/stats.beta_sub-*_${flab_conso}.nii.gz
#  fi
#  if [ ! -f "$gcoef_pairs" ];then
#    3dbucket -fbuc -aglueto $gcoef_pairs $adir/sub-*/$task/sub-*_${task}_${model}/stats.beta_sub-*_${flab_pairs}.nii.gz
#  fi
#  # T-test on one sample of paired contrasts
#  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_${flab_pairs}.nii.gz -mask $mask -exblur 6 \
#    -prefix $tdir/stats.group_${task}_${model}_paired1-${flab_pairs}
#  # T-test on paried two samples
#  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_${flab_words}.nii.gz \
#    -setB $tdir/stats.beta_group_${task}_${model}_${flab_conso}.nii.gz \
#    -mask $mask -exblur 6 -paired \
#    -prefix $tdir/stats.group_${task}_${model}_paired2-${flab_pairs}
#  # T-test on paried two samples within the left-vOT mask
#  3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_${flab_words}.nii.gz \
#    -setB $tdir/stats.beta_group_${task}_${model}_${flab_conso}.nii.gz \
#    -mask $lvot -exblur 6 -paired \
#    -prefix $tdir/stats.lvOT.group_${task}_${model}_paired2-${flab_pairs}
#done
### ---------------------------

## extract coef (PSC) with individual left-vOT mask
model='GLM.wBIM.wPSC.wNR24a'
fpsc="$adir/group_${task}_${model}_PSC.csv"
echo "participant_id,ROI_label,condition,PSC" >> $fpsc
rads=(4 5 6 7 8)  # radii used for individual left-vOT ROIs
for subj in ${subjects[@]};do
  echo -e "Extract beta values (PSC) with ilvOT mask for $task for subject $subj."
  wdir="$adir/$subj/$task"
  oglm="${subj}_${task}_${model}"
  # specify PSC beta files
  coef_words="$wdir/$oglm/stats.beta_${oglm}_${flab_words}.nii.gz"
  coef_conso="$wdir/$oglm/stats.beta_${oglm}_${flab_conso}.nii.gz"
  # extract PSC data for group ROIs
  for iroi in ${rois[@]};do
    froi="$kdir/group/group_${spac}_mask-${iroi}.nii.gz"
    psc_words=$(3dBrickStat -mean -mask $froi $coef_words)
    psc_conso=$(3dBrickStat -mean -mask $froi $coef_conso)
    echo -e "$subj,$iroi,words,$psc_words" >> $fpsc
    echo -e "$subj,$iroi,consonants,$psc_conso" >> $fpsc
  done
  # extract PSC beta for individual ROIs
  for srad in ${rads[@]};do
    froi="$kdir/$subj/${subj}_${spac}_mask-ilvOT-sph${srad}mm.nii.gz"
    psc_words=$(3dBrickStat -mean -mask $froi $coef_words)
    psc_conso=$(3dBrickStat -mean -mask $froi $coef_conso)
    echo -e "$subj,ilvOT-sph${srad}mm,words,$psc_words" >> $fpsc
    echo -e "$subj,ilvOT-sph${srad}mm,consonants,$psc_conso" >> $fpsc
  done
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
