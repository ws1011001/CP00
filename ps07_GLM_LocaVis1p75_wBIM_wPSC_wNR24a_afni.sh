#!/bin/bash

## ---------------------------
## [script name] ps06_GLM_LocaVis1p75_wBIM_wPSC_wNR24a_afni.sh
##
## SCRIPT to ...
##
## By Shuai Wang, [date] 2020-10-20
##
## ---------------------------
## Notes: - BIM, stands for Blur In Mask. 3dBlurInMask is used in this script instead of 3dmerge.
##        - BIGM, stands for Blur In Gray-matter Mask
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
ddir="$mdir/AudioVisAsso"             # experiment Data folder (BIDS put into fMRIPrep)
adir="$ddir/derivatives/afni"         # AFNI output folder
kdir="$ddir/derivatives/masks/group"  # group-averaged masks
# processing parameters
readarray subjects < $mdir/CP00_subjects_BIM.txt
task='task-LocaVis1p75'           # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
bold='desc-preproc_bold'          # the token for the preprocessed BOLD data (without smoothing)
regs='desc-confounds_timeseries'  # the token for fMRIPrep output nuisance regressors
anat='desc-preproc_T1w_brain'     # skull-stripped anatomical image
deno='NR24a'                      # denoising with 12 motion parameters and 6 first PCs of WM and 6 first PCs of CSF
hmpv="dfile_motion_${deno}"       # all head motion NRs that should be regressed out 
ortv="dfile_signal_${deno}"       # all non-motion NRs that should be regressed out
cenv='dfile_censor_FD'            # censors
nrun=1                            # number of runs
fwhm=4                            # double the voxel size (1.75 mm)
hmth=0.5                          # head motion threshold used for censoring
## ---------------------------

## run GLM for each subject
for subj in ${subjects[@]};do
  echo -e "run GLM and statistical contrasts for $task for subject : $subj ......"
  wdir="$adir/$subj/$task"          # the Working folder
  oglm="${subj}_${task}_GLM.wBIGM.wPSC.w${deno}"  # the token for the Output GLM
  # prepare data for GLM
  3dDATAfMRIPrepToAFNI -fmriprep $ddir -subj $subj -task $task -nrun $nrun -deno $deno -spac $spac -cens $hmth -apqc $wdir/$oglm
  # generate AFNI script
  afni_proc.py -subj_id ${subj}_${task} \
    -script $wdir/${oglm}.tcsh \
    -out_dir $wdir/$oglm \
    -copy_anat $adir/$subj/${subj}_${spac}_${anat}.nii.gz \
    -anat_has_skull no \
    -dsets $wdir/${subj}_${task}_run-*_${spac}_${bold}.nii.gz \
    -blocks blur mask scale regress \
    -blur_size $fwhm \
    -blur_in_mask yes \
    -blur_opts_BIM -mask $kdir/group_${spac}_mask-gm0.2_res-${task}.nii.gz \
    -mask_apply anat \
    -regress_polort 2 \
    -regress_local_times \
    -regress_stim_times $wdir/stimuli/${subj}_${task}_events-cond*.txt \
    -regress_stim_labels words consonants catch \
    -regress_basis_multi 'BLOCK(11.809,1)' 'BLOCK(11.809,1)' GAM \
    -regress_motion_file $wdir/confounds/${subj}_${task}_${hmpv}.1D \
    -regress_motion_per_run \
    -regress_censor_extern $wdir/confounds/${subj}_${task}_${cenv}.1D \
    -regress_opts_3dD \
      -ortvec $wdir/confounds/${subj}_${task}_run-01_${ortv}.1D nuisance_regressors \
      -gltsym 'SYM: +words -consonants' -glt_label 1 words-consonants \
    -jobs $njob \
    -html_review_style pythonic
  
  # modify the script nd run it
  sed -e '39 {s/^/#/}' -e '46 {s/^/#/}' $wdir/${oglm}.tcsh > $wdir/${oglm}_exec.tcsh  # comment the line 39 to ignore the exist of out_dir
  tcsh -xef $wdir/${oglm}_exec.tcsh 2>&1 | tee $wdir/output_${oglm}_exec.tcsh         # execute the AFNI script
  
  # backup confounds (.1D files) for the present GLM
  tar -cvzf $wdir/confounds/${oglm}.1D.tar.gz $wdir/confounds/*.1D
  rm -r $wdir/confounds/*.1D
done
## ---------------------------

## summarize data quality metrics
gen_ss_review_table.py -write_table $adir/review_QC_${task}_GLM.wBIGM.wPSC.w${deno}.tsv \
  -infiles $adir/sub-*/$task/sub-*_${task}_GLM.wBIGM.wPSC.w${deno}/out.ss_review.sub-*_${task}.txt -overwrite
## ---------------------------
