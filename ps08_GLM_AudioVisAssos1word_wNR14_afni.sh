#!/bin/bash
## ---------------------------
## [script name] ps08_GLM_AudioVisAssos1word_wNR14_afni.sh
##
## SCRIPT to ...
##
## By Shuai Wang, [date] 2020-10-20
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
ddir="$mdir/AudioVisAsso"                # experiment Data folder (BIDS put into fMRIPrep)
adir="$ddir/derivatives/afni"            # AFNI output folder
# processing parameters
#readarray subjects < $mdir/CP00_subjects.txt
subjects=("sub-01")
task='task-AudioVisAssos1word'    # task name
spac='space-MNI152NLin2009cAsym'  # anatomical template that used for preprocessing by fMRIPrep
bold='desc-preproc_bold'          # the token for the preprocessed BOLD data (without smoothing)
regs='desc-confounds_timeseries'  # the token for fMRIPrep output nuisance regressors
anat='desc-preproc_T1w_brain'     # skull-stripped anatomical image
deno='NR14'                       # denoising strategy
hmpv="dfile_motion_${deno}"       # all head motion NRs that should be regressed out
ortv="dfile_signal_${deno}"       # all non-motion NRs that should be regressed out
cenv='dfile_censor_FD'            # censors
nrun=5                            # number of runs
fwhm=4                            # double the voxel size (1.75 mm)
hmth=0.5
## ---------------------------

## run GLM for each subject
for subj in ${subjects[@]};do
  echo -e "run GLM and statistical contrasts for $task for subject : $subj ......"
  wdir="$adir/$subj/$task"          # the Working folder
  oglm="${subj}_${task}_GLM.w${deno}"  # the token for the Output GLM
  # prepare data for GLM
#  3dDATAfMRIPrepToAFNI -fmriprep $ddir -subj $subj -task $task -nrun $nrun -runtag 'run-0' -deno $deno -spac $spac -cens $hmth -apqc $wdir/$oglm
  3dDATAfMRIPrepToAFNI -fmriprep $ddir -subj $subj -task $task -nrun $nrun -deno $deno -spac $spac -cens $hmth -apqc $wdir/$oglm
  # generate AFNI script
  afni_proc.py -subj_id ${subj}_${task} \
    -script $wdir/${oglm}.tcsh \
    -out_dir $wdir/$oglm \
    -copy_anat $adir/$subj/${subj}_${spac}_${anat}.nii.gz \
    -anat_has_skull no \
    -dsets $wdir/${subj}_${task}_run-*_${spac}_${bold}.nii.gz \
    -blocks blur mask regress \
    -blur_size $fwhm \
    -mask_apply anat \
    -regress_polort 2 \
    -regress_local_times \
    -regress_stim_times $wdir/stimuli/${subj}_${task}_events-cond*.txt \
    -regress_stim_labels WA WV PA PV \
    -regress_basis GAM \
    -regress_motion_file $wdir/confounds/${subj}_${task}_${hmpv}.1D \
    -regress_motion_per_run \
    -regress_censor_extern $wdir/confounds/${subj}_${task}_${cenv}.1D \
    -regress_opts_3dD \
      -ortvec $wdir/confounds/${subj}_${task}_run-01_${ortv}_all.1D nuisance_regressors_run1 \
      -ortvec $wdir/confounds/${subj}_${task}_run-02_${ortv}_all.1D nuisance_regressors_run2 \
      -ortvec $wdir/confounds/${subj}_${task}_run-03_${ortv}_all.1D nuisance_regressors_run3 \
      -ortvec $wdir/confounds/${subj}_${task}_run-04_${ortv}_all.1D nuisance_regressors_run4 \
      -ortvec $wdir/confounds/${subj}_${task}_run-05_${ortv}_all.1D nuisance_regressors_run5 \
      -gltsym 'SYM: +WA -PA' -glt_label 1 WA-PA \
      -gltsym 'SYM: +WV -PV' -glt_label 2 WV-PV \
      -gltsym 'SYM: +WA +WV -PA -PV' -glt_label 3 W-P_A+V \
      -gltsym 'SYM: +WA -WV +PA -PV' -glt_label 4 W+P_A-V \
      -gltsym 'SYM: +WA -WV -PA +PV' -glt_label 5 W-P_A-V \
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

### summarize data quality metrics
#gen_ss_review_table.py -write_table $adir/review_QC_${task}_GLM.w${deno}.tsv \
#  -infiles $adir/sub-*/$task/sub-*_${task}_GLM.w${deno}/out.ss_review.sub-*_${task}.txt -overwrite
### ---------------------------
