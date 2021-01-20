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
task='task-AudioVisAssos1word'    # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
bold='desc-preproc_bold'          # the token for the preprocessed BOLD data (without smoothing)
regs='desc-confounds_timeseries'  # the token for fMRIPrep output nuisance regressors
anat='desc-preproc_T1w_brain'     # skull-stripped anatomical image
deno='NR14'                       # denoising strategy
gmth=0.2                          # gray matter threshold
## ---------------------------

## create masks for each subject
for subj in ${subjects[@]};do
  echo -e "create masks for subject : $subj ......"

  gdir="$pdir/$subj/anat"                   # individual folder that contains anatomical segments
  wdir="$adir/$subj/$task"                  # the Working folder
  oglm="${subj}_${task}_GLM.wPSC.w${deno}"  # the token for the Output GLM, psc means "percent signal change"
  sdir="$kdir/$subj"                        # individual masks folder
  if [ ! -d $sdir ];then mkdir -p $sdir;fi

  # prepare files to create masks
  gm_seg="$gdir/${subj}_${spac}_label-GM_probseg.nii.gz"              # gray matter probability segment
  gm_mask0="$sdir/${subj}_${spac}_GM${gmth}_mask_res-anat.nii.gz"     # gray matter mask in T1 resolution
  gm_mask1="$sdir/${subj}_${spac}_GM${gmth}_mask_res-${task}.nii.gz"  # gray matter mask in task resolution
  epi_mask="$wdir/$oglm/mask_epi_anat.${subj}_${task}+tlrc."          # EPI extent mask

  # create individual gray matter masks
  3dcalc -a $gm_seg -expr "ispositive(a-$gmth)" -prefix $gm_mask0
  3dresample -master $epi_mask -prefix $gm_mask1 -input $gm_mask0
done
## ---------------------------
