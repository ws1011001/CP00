#!/bin/bash

## ---------------------------
## [script name] ps00_DATA_stimuli_timings.sh
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
    mdir='/CP00'                          # the project Main folder @mesocentre
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
wdir="$mdir/AudioVisAsso"      
bdir="$wdir/sourcedata"          # BIDS sourcedata folder
tdir="$bdir/stimuli_timing"      # stimuli timing folder (BIDS .tsv and AFNI timing files)
sfile="$mdir/CP00_subjects.txt"  # Subjects list
## ---------------------------

if [ ! -d $tdir ];then mkdir -p $tdir;fi
while read subj;do
  echo -e "convert stimuli timing for subject: $subj ......"
  fdir="$wdir/$subj/func"
  sdir="$tdir/$subj"
  # task-AudioVisAssos1word, 5 runs
  if [ ! -d "$sdir/task-AudioVisAssos1word" ];then mkdir -p $sdir/task-AudioVisAssos1word;fi 
  cp -r $fdir/${subj}_task-AudioVisAssos1word_*_events.tsv $sdir  # copy BIDS .tsv event files
  1dTimingTools stiming_bids2afni bidsdir=$sdir subj="$subj" task='task-AudioVisAssos1word' nrun=5 \
    conditions="WA,WV,PA,PV" afnidir=$sdir/task-AudioVisAssos1word
  # task-AudioVisAssos2words, 2 runs
  if [ ! -d "$sdir/task-AudioVisAssos2words" ];then mkdir -p $sdir/task-AudioVisAssos2words;fi
  1dTimingTools stiming_tsv2bids funcdir=$fdir subj="$subj" task='task-AudioVisAssos2words' nrun=2 \
    oldpatterns="catch[AV][AV]" replacements="catch" \
    bidsdir=$sdir
  1dTimingTools stiming_bids2afni bidsdir=$sdir subj="$subj" task='task-AudioVisAssos2words' nrun=2 \
    conditions="SISMa,SISMv,SIDMa,SIDMv,DISMa,DISMv,DIDMa,DIDMv,catch" \
    afnidir=$sdir/task-AudioVisAssos2words
  # task-LocaVis1p75, 1 run
  if [ ! -d "$sdir/task-LocaVis1p75" ];then mkdir -p $sdir/task-LocaVis1p75;fi 
  1dTimingTools stiming_tsv2bids funcdir=$fdir subj="$subj" task='task-LocaVis1p75' nrun=1 bidsdir=$sdir
  1dTimingTools stiming_bids2afni bidsdir=$sdir subj="$subj" task='task-LocaVis1p75' nrun=1 \
    conditions="Words,Consonants,catch" \
    afnidir=$sdir/task-LocaVis1p75
  # task-LocaAudio2p5, 1 run
  if [ ! -d "$sdir/task-LocaAudio2p5" ];then mkdir -p $sdir/task-LocaAudio2p5;fi 
  1dTimingTools stiming_tsv2bids funcdir=$fdir subj="$subj" task='task-LocaAudio2p5' nrun=1 bidsdir=$sdir
  1dTimingTools stiming_bids2afni bidsdir=$sdir subj="$subj" task='task-LocaAudio2p5' nrun=1 \
    conditions="Words,Pseudowords,Vocoded,catch" \
    afnidir=$sdir/task-LocaAudio2p5
done < $sfile
