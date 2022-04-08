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
readarray subjects < $mdir/CP00_subjects_gPPI.txt
readarray seeds < $adir/group_masks_labels-gPPI.txt  # seed regions for gPPI
task='task-LocaAudio2p5'          # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
model='GLM.wPSC.wNR24a'
gppi='GLM.wPSC.wNR24a.gPPI'
deno='NR24a'                 # denoising with 12 motion parameters and 6 first PCs of WM and 6 first PCs of CSF
hmpv="dfile_motion_${deno}"  # all head motion NRs that should be regressed out
ortv="dfile_signal_${deno}"  # all non-motion NRs that should be regressed out
cenv='dfile_censor_FD'       # censors
TRor=1.2  # original TR inseconds
TRup=0.1  # upsampled TR (seconds)
DurC=12   # duration of a condition in the design
nTRs=335  # number of TRs
TPup=$(echo "$TRor / $TRup" | bc)     # upsampled scale size: original TR divided by upsampled TR
DurR=$(echo "$TRor * $nTRs" | bc -l)  # duration of the whole run
nUPs=$(echo "$TPup * $nTRs" | bc)     # number of time points in the upsampled whole run
mask="$kdir/group/group_${spac}_mask-gm0.2_res-${task}.nii.gz"  # GM mask
## ---------------------------

echo -e "========== START JOB at $(date) =========="

## Prepare design vector for each condition
for subj in ${subjects[@]};do
  echo -e "Prepare design vectors for $task for $subj. "
  wdir="$adir/$subj/$task"
  stim="$wdir/stimuli"
  pdir="$wdir/${subj}_${task}_${gppi}"
  # convert condition stiming to upsampled design vector
  if [ ! -d $pdir ];then
    mkdir -p $pdir
    for i in `seq 1 3`;do  # three conditions: words pseudowords scrambled
      fcon="$wdir/stimuli/${subj}_${task}_events-cond${i}.txt"
      fvec="$pdir/${subj}_${task}_events-ideal-cond${i}.1D"
      timing_tool.py -timing $fcon -tr $TRup -stim_dur $DurC -run_len $DurR -min_frac 0.3 -timing_to_1D $fvec
    done
  fi
done
## ---------------------------

## Prepare PPI regressors for each seed
for seed in ${seeds[@]};do
  echo -e "Prepare deconvolved time-series for $seed. "
  froi="$kdir/group/group_${spac}_mask-${seed}.nii.gz"
  for subj in ${subjects[@]};do
    wdir="$adir/$subj/$task"
    oglm="$wdir/${subj}_${task}_${model}"
    pdir="$wdir/${subj}_${task}_${gppi}"
    # extract seed time-series
    ferr="$oglm/errts.${subj}_${task}+tlrc."
    fsts="$pdir/$seed/${subj}_${task}_mask-${seed}_ts.1D"  # seed time-series
    if [ ! -d "$pdir/$seed" ];then mkdir -p $pdir/$seed;fi  # create seed folder if not exist
    if [ ! -f $fsts ];then
      3dmaskave -mask $froi -quiet $ferr > $fsts
      # deconvolve time-series
      1dDeconv -func block -dur $DurC --tr-up $TRup --n-up $TPup -input $fsts &  # the output file's name ends with _deconv.1D
    fi
  done
  wait  # parallel processing for deconvolution since it's slow
  # obtain the interaction regressors
  for subj in ${subjects[@]};do
    echo -e "Extract PPI regressors for $seed for $task for $subj. "
    wdir="$adir/$subj/$task"
    oglm="$wdir/${subj}_${task}_${model}"
    pdir="$wdir/${subj}_${task}_${gppi}"
    # estimate interaction
    fsts="$pdir/$seed/${subj}_${task}_mask-${seed}_ts_deconv.1D"  # seed time-series
    firf="$pdir/$seed/${subj}_${task}_mask-${seed}_ts_IRF.1D"     # impulse response function
    for i in `seq 1 3`;do
      fvec="$pdir/${subj}_${task}_events-ideal-cond${i}.1D"
      fcts="$pdir/$seed/${subj}_${task}_deconv-cond${i}.1D"
      frec="$pdir/$seed/${subj}_${task}_reconv-cond${i}.1D"  # reconvolution
      fppi="$pdir/$seed/${subj}_${task}_gPPI-cond${i}.1D"
      if [ ! -f $fppi ];then
        1deval -a $fsts\' -b $fvec -expr 'a*b' > $fcts
        waver -FILE $TRup $firf -input $fcts -numout $nUPs > $frec
        # downsample reconv.
        1dcat $frec'{0..$('$TPup')}' > $fppi
      fi
    done  
  done
done
## ---------------------------

## run GLM with additional PPI regressors for each subject
for seed in ${seeds[@]};do
  for subj in ${subjects[@]};do
    echo -e "Run gPPI with $seed for $task for $subj. "
    wdir="$adir/$subj/$task"         # the Working path
    oglm="${subj}_${task}_${model}"  # the token for the previous GLM
    pglm="${subj}_${task}_${gppi}"   # the token for the PPI GLM
    pdir="$wdir/$pglm/$seed"         # the PPI seed folder
    # prepare data for GLM
    tar -vxf $wdir/confounds/${oglm}.1D.tar.gz --strip-components=7 -C $wdir/confounds  # unzip confounds files
    # generate AFNI script
    afni_proc.py -subj_id ${subj}_${task} \
      -script $wdir/${pglm}.tcsh \
      -out_dir $pdir \
      -copy_anat $adir/$subj/${subj}_${spac}_${anat}.nii.gz \
      -anat_has_skull no \
      -dsets $wdir/${oglm}/pb02.${subj}_${task}.r01.scale+tlrc. \
      -blocks regress \
      -regress_polort 2 \
      -regress_local_times \
      -regress_stim_times $wdir/stimuli/${subj}_${task}_events-cond*.txt \
      -regress_stim_labels words pseudowords scrambled catch \
      -regress_basis_multi 'BLOCK(12.06,1)' 'BLOCK(12.06,1)' 'BLOCK(12.06,1)' GAM \
      -regress_extra_stim_files $pdir/${subj}_${task}_gPPI-cond*.1D \
      -regress_extra_stim_labels gppi.words gppi.pseudowords gppi.scrambled \
      -regress_motion_file $wdir/confounds/${subj}_${task}_${hmpv}.1D \
      -regress_motion_per_run \
      -regress_censor_extern $wdir/confounds/${subj}_${task}_${cenv}.1D \
      -regress_opts_3dD \
        -ortvec $wdir/confounds/${subj}_${task}_run-01_${ortv}.1D nuisance_regressors \
        -gltsym 'SYM: +words -pseudowords' -glt_label 1 words-pseudowords \
        -gltsym 'SYM: +words -scrambled' -glt_label 2 words-scrambled \
        -gltsym 'SYM: +pseudowords -scrambled' -glt_label 3 pseudowords-scrambled \
        -gltsym 'SYM: +gppi.words -gppi.pseudowords' -glt_label 4 gPPI:words-pseudowords \
        -gltsym 'SYM: +gppi.words -gppi.scrambled' -glt_label 5 gPPI:words-scrambled \
        -gltsym 'SYM: +gppi.pseudowords -gppi.scrambled' -glt_label 6 gPPI:pseudowords-scrambled \
      -jobs $njob \
      -html_review_style pythonic
    
    # modify the script nd run it
    #sed -e '39 {s/^/#/}' -e '46 {s/^/#/}' $wdir/${pglm}.tcsh > $wdir/${pglm}_exec.tcsh  # comment the line 39 to ignore the exist of out_dir
    #tcsh -xef $wdir/${pglm}_exec.tcsh 2>&1 | tee $wdir/output_${pglm}_exec.tcsh         # execute the AFNI script
    
    # clean up confounds .1D files used by the present GLM
    rm -r $wdir/confounds/*.1D
  done
done
## ---------------------------


echo -e "========== ALL DONE! at $(date) =========="
