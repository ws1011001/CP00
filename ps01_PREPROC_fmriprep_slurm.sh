#!/bin/bash
# by Shuai Wang

#SBATCH -J fMRIPrep
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A a222
#SBATCH -t 3-12
#SBATCH --cpus-per-task=32
#SBATCH --mem=128gb
#SBATCH -o ./ps01_PREPROC_fmriprep_%j.out
#SBATCH -e ./ps01_PREPROC_fmriprep_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ws1011001@gmail.com
#SBATCH --mail-type=BEGIN,END

wdir='/scratch/swang/agora/CP00'  # the project Main folder
simg='/scratch/swang/simages'     # singularity images folder

echo “Pre-processing using fMRIPrep on: $SLURM_NODELIST”
rm -r $wdir/SWAP/*

singularity run --cleanenv -B $wdir:/work $simg/fmriprep-20.2.0 --fs-license-file /work/license.txt \
  /work/AudioVisAsso /work/AudioVisAsso/derivatives participant \
  --participant-label 01 02 03 \
  -w /work/SWAP \
  --ignore slicetiming \
  --output-spaces MNI152NLin2009cAsym \
  --fs-no-reconall \
  --return-all-components \
  --stop-on-first-crash \
  --skip_bids_validation

rm -r $wdir/SWAP/*
#singularity run --cleanenv -B $wdir:/work $simg/fmriprep-20.1.1 --fs-license-file /work/license.txt \
#  /work/AudioVisAsso /work/AudioVisAsso/derivatives participant --participant-label $subj --task-id LocaVis1p75 \
#  -w /work/SWAP --anat-derivatives /work/AudioVisAsso/derivatives/fmriprep/sub-pilot2rc/anat --ignore slicetiming --output-spaces MNI152NLin2009cAsym --fs-no-reconall \
#  --stop-on-first-crash --skip_bids_validation
