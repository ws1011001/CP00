## ---------------------------
## [script name] psmeta_gather_univariate_results.sh
##
## SCRIPT to sort up univariate results (AFNI stats.* files) from individual folders into group-level folders. The 
##           organized results would be used to examine results one by one and to do simple group stats on a local PC.
##
## By Shuai Wang, [date] 2021-01-21
##
## ---------------------------
## Notes: - only use Bash so it could run on the local node.
##   
##
## ---------------------------

## set environment (packages, functions, working path etc.)
# setup path
mdir="/scratch/swang/agora/CP00"
ddir="$mdir/AudioVisAsso"          # experiment Data folder (BIDS put into fMRIPrep)
fdir="$ddir/derivatives/fmriprep"  # fMRIPrep output folder
adir="$ddir/derivatives/afni"      # AFNI output folder
rdir="$mdir/results"               # gathered results
qdir="$rdir/QC_fmriprep"           # QC reports of fMRIPrep
# processing parameters
readarray subjects < $mdir/CP00_subjects.txt
tasks=("task-LocaVis1p75" "task-LocaAudio2p5" "task-AudioVisAssos1word" "task-AudioVisAssos2words")
# additional options
isQCReport=true
isClean_QCVols=true
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## gather fMRIPrep QC reports
if $isQCReport;then
  if [ ! -d $qdir ];then mkdir -p $qdir;fi 
  # copy logs and HTMLs
  cp -r $fdir/logs $qdir
  cp -r $fdir/dataset_description.json $qdir
  cp -r $fdir/sub-*.html $qdir
  # copy QC figures
  for subj in ${subjects[@]};do
    if [ ! -d "$qdir/$subj" ];then
      mkdir -p $qdir/$subj
    fi
    cp -r $fdir/$subj/figures $qdir/$subj
    cp -r $fdir/$subj/log $qdir/$subj
  done
fi
## ---------------------------

### gather results for each task
#for task in ${tasks[@]};do
#  echo -e "========== start gathering results (stats.* files) for $task =========="
#  tdir="$rdir/$task"
#  if [ ! -d $tdir ];then mkdir -p $tdir;fi
#  # collect files for each subject
#  for subj in ${subjects[@]};do
#    wdir="$adir/$subj/$task"  
#    echo -e "# enter the task folder : $wdir #"
#    cd $wdir
#    # collect files from each model
#    for iglm in $(ls -d *GLM*/);do
#      oglm=${iglm%%/}    # remove the ending /
#      glm=${oglm:7}      # remove the starting subject id
#      gdir="$tdir/$glm"  # GLM folder in the task result folder
#      if [ ! -d $gdir ];then mkdir -p $gdir;fi
#      # copy stats.* files to the GLM folder
#      cp -r $wdir/$oglm/stats*tlrc* $gdir
#      # copy QC report to the GLM folder
#      cp -r $wdir/$oglm/QC_${subj}_${task} $gdir      # QC report
#      cp -r $wdir/$oglm/X.* $gdir/QC_${subj}_${task}  # design matrix
#
#      # additional option: remove AFNI volumes that used for QC report
#      if $isClean_QCVols;then
#        echo -e "clean up AFNI QC volumes in $oglm"
#        rm -r $wdir/$oglm/pb00.${subj}_${task}.*.tcat+orig.*
#        rm -r $wdir/$oglm/pb02.${subj}_${task}.*.volreg+tlrc.*
#        touch $wdir/$oglm/CLEANUP_Removed_AFNI_QC_Volumes.note  # leave a message in the folder
#      fi
#    done
#  done
#  echo -e "========== finish gathering results (stats.* files) for $task =========="
#done
### ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
