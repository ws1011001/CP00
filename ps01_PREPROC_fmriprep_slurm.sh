#!/bin/bash
## ---------------------------
## [script name] ps01_PREPROC_fmriprep_slurm.sh
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
# setup paarameters for slurm
#SBATCH -J fMRIPrep
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A a222
#SBATCH -t 6-12
#SBATCH --cpus-per-task=16
#SBATCH --mem=128gb
#SBATCH -o ./ps01_PREPROC_fmriprep_%j.out
#SBATCH -e ./ps01_PREPROC_fmriprep_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ws1011001@gmail.com
#SBATCH --mail-type=BEGIN,END
# setup working path
wdir='/scratch/swang/agora/CP00'  # the project Main folder
simg='/scratch/swang/simages'     # singularity images folder
# subjects info
declare -a subjects=$(seq -w 1 22)
## ---------------------------

## do pre-process for each subject
for sid in ${subjects[@]};do
  echo -e “Pre-processing subject: sub-${sid} using fMRIPrep on: $SLURM_NODELIST”
  rm -r $wdir/SWAP/*  # remove temporary files 
  # pre-processing using fMRIPrep 
  singularity run --cleanenv -B $wdir:/work $simg/fmriprep-20.2.0 --fs-license-file /work/license.txt \
    /work/AudioVisAsso /work/AudioVisAsso/derivatives participant \
    --participant-label $sid \
    -w /work/SWAP \
    --ignore slicetiming \
    --use-syn-sdc \
    --output-spaces MNI152NLin2009cAsym \
    --fs-no-reconall \
    --return-all-components \
    --stop-on-first-crash \
    --skip_bids_validation
  echo -e "Finish pre-processing for subject :sub-${sid}. Please check it out."
done
rm -r $wdir/SWAP/*  # double-check to clean temporary files
## ---------------------------

## process logs
#singularity run --cleanenv -B $wdir:/work $simg/fmriprep-20.1.1 --fs-license-file /work/license.txt \
#  /work/AudioVisAsso /work/AudioVisAsso/derivatives participant --participant-label $subj --task-id LocaVis1p75 \
#  -w /work/SWAP --anat-derivatives /work/AudioVisAsso/derivatives/fmriprep/sub-pilot2rc/anat --ignore slicetiming --output-spaces MNI152NLin2009cAsym --fs-no-reconall \
#  --stop-on-first-crash --skip_bids_validation
## ---------------------------
