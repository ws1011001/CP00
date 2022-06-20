#!/bin/bash
## ---------------------------
## [script name] ps15_STAT_LocaAudio2p5_ttests_afni.sh
##
## SCRIPT to perform T-tests to extract group results and to determine the denoising strategy.
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
task='task-LocaAudio2p5'          # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
mask="$kdir/group/group_${spac}_mask-gm0.2_res-${task}.nii.gz"  # GM mask
models=("GLM.wPSC.wNR24a")
# index the stat volumes
eidx=(1 4 7)
flab=("words" "pseudowords" "scrambled")
#eidx=(13 16 19)  # coefficients
fidx=(14 17 20)  # T values
#flab=("words-pseudowords" "words-scrambled" "pseudowords-scrambled")  # contrast labels
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
#    # extract coef maps for group analysis
#    i=0
#    for ilab in ${flab[@]};do
#      coef="$wdir/$oglm/stats.beta_${oglm}_${ilab}.nii.gz"
#      if [ ! -f $coef ];then
#        3dbucket -fbuc -prefix $coef "${stat}[${eidx[i]}]"
#      fi
#      let i+=1
#    done
#  done
#done
### ---------------------------

### group T-tests
#tdir="$adir/group/$task"
#if [ ! -d $tdir ];then mkdir -p $tdir;fi
#for model in ${models[@]};do
#  for ilab in ${flab[@]};do
#    # stack up subjects for group analysis
#    gcoef="$tdir/stats.beta_group_${task}_${model}_${ilab}.nii.gz"
#    if [ ! -f $gcoef ];then
#      3dbucket -fbuc -aglueto $gcoef $adir/sub-*/$task/sub-*_${task}_${model}/stats.beta_sub-*_${ilab}.nii.gz
#    fi
#    # T-test
#    3dttest++ -setA $tdir/stats.beta_group_${task}_${model}_${ilab}.nii.gz -mask $mask -exblur 6 -prefix $tdir/stats.group_${task}_${model}_${ilab}
#  done  
#done
### ---------------------------

## extract coef (PSC) with individual left-vOT mask
model='GLM.wPSC.wNR24a'
fpsc="$adir/group_${task}_${model}_PSC.csv"
echo "participant_id,ROI_label,condition,PSC" >> $fpsc
rads=(4 5 6 7 8)  # radii used for individual left-vOT ROIs
for subj in ${subjects[@]};do
  echo -e "Extract beta values (PSC) with ilvOT mask for $task for subject $subj."
  wdir="$adir/$subj/$task"
  oglm="${subj}_${task}_${model}"
  # specify PSC beta files
  coef_words="$wdir/$oglm/stats.beta_${oglm}_words.nii.gz"
  coef_pword="$wdir/$oglm/stats.beta_${oglm}_pseudowords.nii.gz"
  coef_scrab="$wdir/$oglm/stats.beta_${oglm}_scrambled.nii.gz"
  # extract PSC data for group ROIs
  for iroi in ${rois[@]};do
    froi="$kdir/group/group_${spac}_mask-${iroi}.nii.gz"
    fbig="$kdir/group/group_${spac}_mask-${iroi}_tmp.nii.gz"
    3dresample -master $mask -input $froi -prefix $fbig
    psc_words=$(3dBrickStat -mean -mask $fbig $coef_words)
    psc_pword=$(3dBrickStat -mean -mask $fbig $coef_pword)
    psc_scrab=$(3dBrickStat -mean -mask $fbig $coef_scrab)
    echo -e "$subj,$iroi,words,$psc_words" >> $fpsc
    echo -e "$subj,$iroi,pseudowords,$psc_pword" >> $fpsc
    echo -e "$subj,$iroi,scrambled,$psc_scrab" >> $fpsc
    rm -r $fbig
  done
  # extract PSC beta for individual ROIs
  for srad in ${rads[@]};do
    froi="$kdir/$subj/${subj}_${spac}_mask-ilvOT-sph${srad}mm.nii.gz"
    fbig="$kdir/$subj/${subj}_${spac}_mask-ilvOT-sph${srad}mm_tmp.nii.gz"
    3dresample -master $mask -input $froi -prefix $fbig
    psc_words=$(3dBrickStat -mean -mask $fbig $coef_words)
    psc_pword=$(3dBrickStat -mean -mask $fbig $coef_pword)
    psc_scrab=$(3dBrickStat -mean -mask $fbig $coef_scrab)
    echo -e "$subj,ilvOT-sph${srad}mm,words,$psc_words" >> $fpsc
    echo -e "$subj,ilvOT-sph${srad}mm,pseudowords,$psc_pword" >> $fpsc
    echo -e "$subj,ilvOT-sph${srad}mm,scrambled,$psc_scrab" >> $fpsc
    rm -r $fbig
  done
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
