#!/bin/bash

#SBATCH -J RETROICOR
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A a222
#SBATCH -t 1-12
#SBATCH --cpus-per-task=16
#SBATCH --mem=128gb
#SBATCH -o ./RETROICOR_%j.out
#SBATCH -e ./RETROICOR_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ws1011001@gmail.com
#SBATCH --mail-type=BEGIN,END

# setup path
idir='/scratch/swang/simages'  # singularity images directory
mdir='/scratch/swang/agora/CP00'     # the project main directory
scripts='/CP00/scripts'        # scripts folder in Sy

# processing log
#echo -e 'Running ps00_DATA_stimuli_timings.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps00_DATA_stimuli_timings.sh

#echo -e 'Running ps01_PREPROC_ricor_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps01_PREPROC_ricor_afni.sh

echo -e 'Running ps02_GLM_LocaVis1p75_wNR50_afni.sh with singularity'
singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNR50_afni.sh
