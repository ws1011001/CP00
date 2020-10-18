#!/bin/bash

## ---------------------------
## [script name] ps01_PREPROC_ricor_afni.sh
##
## SCRIPT to ...
##
## By Shuai Wang, [date] 2020-10-19
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
    ;;
  totti)
    mdir='/data/mesocentre/data/agora/CP00'  # the project Main folder @totti
    ;;
  *)
    echo -e "Please input a valid platform!"
    exit 1
esac
# setup path
ddir="$mdir/AudioVisAsso"                # experiment Data folder (BIDS put into fMRIPrep)
pdir="$ddir/sourcedata/physio_log"       # physiological data
# processing parameters
readarray subjects < $mdir/CP00_subjects.txt
tasks=("task-LocaVis1p75" "task-LocaAudio2p5" "task-AudioVisAssos1word" "task-AudioVisAssos2words")           # task name
nruns=(1 1 5 2)
recordsfreq=200
## ---------------------------

## do RETROICOR for each subject
for subj in ${subjects[@]};do
  echo -e "Do RETROICOR for subject : $subj ......"
  # backup original data
  if [ ! -d "$ddir/${subj}_" ];then
    cp -r $ddir/$subj $ddir/${subj}_
  fi
  # do RETROICOR for each task
  i=0
  for task in ${tasks[@]};do
    nrun=${nruns[i]}
    let i+=1
    echo -e "Do RETROICOR for $task with $nrun runs ......"
    wdir="$pdir/$subj/$task"          # the Working folder
    if [ ! -d $wdir ];then
      mkdir -p $wdir
    fi
    # prepare physiological data
    echo -e "Preparing (slice-based) Physiological Regressors ......"
    slicenumber=$(3dinfo -nk $ddir/$subj/func/${subj}_${task}_run-01_bold.nii.gz)
    TR=$(3dinfo -tr $ddir/$subj/func/${subj}_${task}_run-01_bold.nii.gz)
    echo -e "BOLD Info: slice number is $slicenumber, TR is $TR"
    # convert log files to 1D time series
    1dPhysLogToAFNI SiemensTics dir="$pdir/$subj" subj=$subj task=$task nrun=$nrun tr=$TR freq=$recordsfreq
    # generate slice-based physiological regressors
    slicetiming="$pdir/$subj/${subj}_${task}_bold_silce-onsets.1D"
    for irun in $(seq 1 $nrun);do
      frun=`printf "run-%02d" $irun`
      nTR=$(3dinfo -nv $ddir/$subj/func/${subj}_${task}_${frun}_bold.nii.gz)
      RetroTS.py -r $pdir/$subj/${subj}_${task}_${frun}_recording-respiratory-f200hz_physio.1D \
                 -c $pdir/$subj/${subj}_${task}_${frun}_recording-cardiac-f200hz_physio.1D \
                 -p $recordsfreq -n $slicenumber -v $TR \
                 -slice_offset $slicetiming -slice_order custom \
                 -prefix $wdir/${subj}_${task}_${frun}_recording_physio
      nvol=$(3dinfo -ni $wdir/${subj}_${task}_${frun}_recording_physio.slibase.1D)
      # check the number of volumes
      if [ $nTR != $nvol ];then
        echo -e "The number of TRs of BOLD is $nTR, while the number of volumes of physiological regressors is $nvol. They are not equal. QUIT!"
        exit 1
      fi
    done
    # copy BOLD data
    cp -r $ddir/$subj/func/${subj}_${task}_run-*_bold.nii.gz $wdir
    # perform ricor in AFNI
    echo -e "Performing RICOR using AFNI for $task ..."
    cd $wdir  # go into working folder
    afni_proc.py -subj_id $task \
                 -dsets ${subj}_${task}_run-*_bold.nii.gz \
                 -blocks despike ricor \
                 -ricor_regs ${subj}_${task}_run-*_recording_physio.slibase.1D \
                 -execute
    # replace original BOLD data
    for irun in $(seq 1 $nrun);do
      frun=`printf "%02d" $irun`
      frico="${task}.results/pb02.${task}.r${frun}.ricor+orig"
      forig="$ddir/$subj/func/${subj}_${task}_run-${frun}_bold.nii.gz"
      if [ -f "${frico}.HEAD" ];then
        rm -r $forig
        3dcopy $frico $forig
      else
        echo -e "Lack of RETROICOR results for $subj $task Run $irun. QUIT!"
        exit 1
      fi
    done
    echo -e "Successfully done RETROICOR for $task of $subj!"
  done
done
## ---------------------------

