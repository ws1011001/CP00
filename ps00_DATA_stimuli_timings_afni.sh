#!/bin/bash
## ---------------------------
## [script name] ps00_DATA_stimuli_timings.sh
## SCRIPT to ...
##
## By Shuai Wang, 2020-10
## ---------------------------
## Notes:
## ---------------------------

## set environment (packages, functions, working path etc.)
# platform
platform='local'
case "$platform" in
	mesoc)
		dir_main='/CP00'                          # the project Main folder @mesocentre
  	  	export PATH="$dir_main/nitools:$PATH"  # setup tools if @mesocentre
  	  	;;
  	local)
		dir_main='/data/mesocentre/data/agora/CP00'  # the project Main folder @totti
  	  	;;
  	*)
		echo -e "Please input a valid platform!"
  	  	exit 1
esac
# setup path
dir_bids="$dir_main/AudioVisAsso"      
dir_data="$dir_bids/sourcedata"          # BIDS sourcedata folder
dir_stim="$dir_data/stimuli_timing"      # stimuli timing folder (BIDS .tsv and AFNI timing files)
f_subjs="$dir_main/CP00_subjects.txt"  # Subjects list
## ---------------------------

if [ ! -d $dir_stim ];then mkdir -p $dir_stim;fi
afni_AVA1="WA_cor,WA_inc,WV_cor,WV_inc,PA_cor,PA_inc,PV_cor,PV_inc"
while read subj;do
	echo -e "Convert stimuli timing for the subject $subj. "
  	#fdir="$dir_bids/$subj/func"
  	dir_subj="$dir_stim/$subj"
	# task-AudioVisAssos1word, 5 runs
	dir_task="$dir_subj/task-AudioVisAssos1word"
  	#if [ ! -d "$dir_subj/task-AudioVisAssos1word" ];then mkdir -p $dir_subj/task-AudioVisAssos1word;fi 
  	#cp -r $fdir/${subj}_task-AudioVisAssos1word_*_events.tsv $dir_subj  # copy BIDS .tsv event files
	1dTimingTools bids2afni dir_bids=$dir_task dir_afni=$dir_task subj=$subj task='task-AudioVisAssos1word' nrun=5 \
		conditions=$afni_AVA1
	#1dTimingTools stiming_bids2afni biddir_subj=$dir_subj subj="$subj" task='task-AudioVisAssos1word' nrun=5 conditions="WA,WV,PA,PV" afnidir=$dir_subj/task-AudioVisAssos1word
  	## task-AudioVisAssos2words, 2 runs
  	#if [ ! -d "$dir_subj/task-AudioVisAssos2words" ];then mkdir -p $dir_subj/task-AudioVisAssos2words;fi
  	#1dTimingTools stiming_tsv2bids funcdir=$fdir subj="$subj" task='task-AudioVisAssos2words' nrun=2 \
  	#  conditions='none' oldpatterns="catch[AV][AV]" replacements="catch" \
  	#  biddir_subj=$dir_subj
  	#1dTimingTools stiming_bids2afni biddir_subj=$dir_subj subj="$subj" task='task-AudioVisAssos2words' nrun=2 \
  	#  conditions="SISMa,SISMv,SIDMa,SIDMv,DISMa,DISMv,DIDMa,DIDMv,catch" \
  	#  afnidir=$dir_subj/task-AudioVisAssos2words
  	## task-LocaVis1p75, 1 run
  	#if [ ! -d "$dir_subj/task-LocaVis1p75" ];then mkdir -p $dir_subj/task-LocaVis1p75;fi 
  	#1dTimingTools stiming_tsv2bids funcdir=$fdir subj="$subj" task='task-LocaVis1p75' nrun=1 conditions='none' oldpatterns='none' replacements='none' biddir_subj=$dir_subj
  	#1dTimingTools stiming_bids2afni biddir_subj=$dir_subj subj="$subj" task='task-LocaVis1p75' nrun=1 \
  	#  conditions="Words,Consonants,catch" \
  	#  afnidir=$dir_subj/task-LocaVis1p75
  	#1dTimingTools stiming_bids2afni biddir_subj=$dir_subj subj="$subj" task='task-LocaVis1p75' nrun=1 \
  	#  conditions="Words,Consonants,Fixation,catch" \
  	#  afnidir=$dir_subj/task-LocaVis1p75 design='fix'
  	## task-LocaAudio2p5, 1 run
  	#if [ ! -d "$dir_subj/task-LocaAudio2p5" ];then mkdir -p $dir_subj/task-LocaAudio2p5;fi 
  	#1dTimingTools stiming_tsv2bids funcdir=$fdir subj="$subj" task='task-LocaAudio2p5' nrun=1 conditions='none' oldpatterns='none' replacements='none' biddir_subj=$dir_subj
  	#1dTimingTools stiming_bids2afni biddir_subj=$dir_subj subj="$subj" task='task-LocaAudio2p5' nrun=1 \
  	#  conditions="Words,Pseudowords,Vocoded,catch" \
  	#  afnidir=$dir_subj/task-LocaAudio2p5
done < $f_subjs
