## ---------------------------
## [script name] psmeta_gather_univariate_results_os.sh
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
kdir="$ddir/derivatives/masks"     # individual masks
rdir="$mdir/results"               # gathered results
qdir="$rdir/QC_fmriprep"           # QC reports of fMRIPrep
# processing parameters
readarray subjects < $mdir/CP00_subjects.txt
tasks=("task-LocaVis1p75" "task-LocaAudio2p5" "task-AudioVisAssos1word" "task-AudioVisAssos2words")
obsolete_models=("NR12" "NR14")
# manip options
isQCs_FMRIPREP=false
isCollect_AFNI=false
isClean_tmasks=true  # remove task masks
isClean_Models=false
isClean_QCVols=false
isClean_LSSraw=false
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## gather fMRIPrep QC reports
if $isQCs_FMRIPREP;then
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

## remove task EPI based masks
if $isClean_tmasks;then
  # remove individual masks
  for subj in ${subjects[@]};do
    rm -r $kdir/$subj/*_res-task*
  done
  # remove group masks
  rm -r $kdir/group/*_res-task*
fi
## ---------------------------

## gather results for each task
for task in ${tasks[@]};do
  echo -e "========== start gathering results (stats.* files) for $task =========="
  tdir="$rdir/$task"
  if [ ! -d $tdir ];then mkdir -p $tdir;fi
  # check each subject
  for subj in ${subjects[@]};do
    wdir="$adir/$subj/$task"  
    echo -e "# enter the task folder : $wdir #"
    cd $wdir
    # clean up obsolete models
    if $isClean_Models;then
      for om in ${obsolete_models[@]};do
        rm -r *${om}*
        rm -r confounds/*${om}*
        echo -e "Clean up results of models with $om ......"
      done
    fi
    # check each model
    for iglm in $(ls -d *GLM*/);do
      oglm=${iglm%%/}    # remove the ending /
      glm=${oglm:7}      # remove the starting subject id
      gdir="$tdir/$glm"  # GLM folder in the task result folder
      if [ ! -d $gdir ];then mkdir -p $gdir;fi
      # collect AFNI results
      clnote="$wdir/$oglm/COLLECT_Copied_AFNI_Stats_and_QC.note"
      if $isCollect_AFNI && [ ! -f $clnote ];then
        # copy stats.* files to the GLM folder
        cp -r $wdir/$oglm/stats*tlrc* $gdir
        # copy QC report to the GLM folder
        cp -r $wdir/$oglm/QC_${subj}_${task} $gdir      # QC report
        cp -r $wdir/$oglm/X.* $gdir/QC_${subj}_${task}  # design matrix
        touch $clnote  # leave a message in the folder
      fi
      # remove AFNI volumes that used for QC report
      qcnote="$wdir/$oglm/CLEANUP_Removed_AFNI_QC_Volumes.note"
      if $isClean_QCVols && [ ! -f $qcnote ];then
        echo -e "clean up AFNI QC volumes in $oglm"
        rm -r $wdir/$oglm/pb00.${subj}_${task}.*.tcat+orig.*
        rm -r $wdir/$oglm/pb02.${subj}_${task}.*.volreg+tlrc.*
        touch $qcnote  # leave a message in the folder
      fi
      # remove raw data that used to do LSS
      lsnote="$wdir/$oglm/trial-wise_estimates/CLEANUP_Removed_LSS_Inputs.note"
      if $isClean_LSSraw && [ ! -f $lsnote ] && [ -d "$wdir/$oglm/trial-wise_estimates" ];then
        echo -e "clean up inputs to 3dLSS in $oglm"
        rm -r $wdir/$oglm/trial-wise_estimates/LSS.${subj}_${task}.all.scale+tlrc*
        touch $lsnote
      fi
    done
  done
  echo -e "========== finish gathering results (stats.* files) for $task =========="
done
## ---------------------------

echo -e "========== ALL DONE! at $(date) =========="
