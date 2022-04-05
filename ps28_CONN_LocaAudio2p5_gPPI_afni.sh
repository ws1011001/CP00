#!/bin/bash
## ---------------------------
## [script name] ps28_CONN_LocaAudio2p5_gPPI_afni.sh
##
## SCRIPT to do Generalized Form of Context-Dependent Psychophysiological Interactions (gPPI) on the auditory localizer.
##
## By Shuai Wang, [date] 2022-04-04
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
readarray seeds < $adir/group_masks_labels-PPI.txt  # seed regions for gPPI
task='task-LocaAudio2p5'          # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
model='GLM.wPSC.wNR24a'
gppi='GLM.wPSC.wNR24a.gPPI'
mask="$kdir/group/group_${spac}_mask-gm0.2_res-${task}.nii.gz"  # GM mask
flab=("words" "pseudowords" "scrambled")
TRup=0.1  # upsampled TR (seconds)
TPup=12   # upsampled scale size: original TR divided by upsampled TR
DurC=12   # duration of a condition in the design
DurR=402  # duration of the whole run
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## Prepare design vector for each condition
for subj in ${subjects[@]};do
  echo -e "Prepare design vectors for $task for $subj. "
  wdir="$adir/$subj/$task"
  stim="$wdir/stimuli"
  pdir="$wdir/${subj}_${task}_${gppi}"
  if [ ! -d $pdir ];then mkdir -p $pdir;fi
  # convert condition stiming to upsampled design vector
  fwrd="$wdir/stimuli/${subj}_${task}_events-cond1.txt"  # words
  fpdw="$wdir/stimuli/${subj}_${task}_events-cond2.txt"  # pseudowords
  fscr="$wdir/stimuli/${subj}_${task}_events-cond3.txt"  # scrambled
  timing_tool.py -timing $fwrd -tr $TRup -stim_dur $DurC -run_len $DurR -min_frac 0.3 -timing_to_1D $pdir/ppi_ideal_words.1D
  timing_tool.py -timing $fpdw -tr $TRup -stim_dur $DurC -run_len $DurR -min_frac 0.3 -timing_to_1D $pdir/ppi_ideal_pseudowords.1D
  timing_tool.py -timing $fscr -tr $TRup -stim_dur $DurC -run_len $DurR -min_frac 0.3 -timing_to_1D $pdir/ppi_ideal_scrambled.1D
done
## ---------------------------

## Prepare PPI regressors for each seed
for seed in ${seeds[@]};do
  echo -e "Prepare PPI regressors for $task for $subj. "
  froi="$kdir/group/group_${spac}_mask-${seed}.nii.gz"
  for subj in ${subjects[@]};do
    wdir="$adir/$subj/$task"
    oglm="$wdir/${subj}_${task}_${model}"
    pdir="$wdir/${subj}_${task}_${gppi}"
    # extract seed time-series
    ferr="$oglm/errts.${subj}_${task}+tlrc."
    fsts="$pdir/${subj}_${task}_mask-${seed}_ts.1D"  # seed time-series
    3dmaskave -mask $froi -quiet $ferr > $fsts
    # deconvolve time-series
    1dDeconv --tr-up $TRup --n-up $TPup -input $fsts  # the output file's name ends with _deconv.1D
  done
done
## ---------------------------


echo -e "========== ALL DONE! at $(date) =========="
