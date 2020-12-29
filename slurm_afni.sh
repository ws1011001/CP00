#!/bin/bash

#SBATCH -J AFNI-GLM
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A a222
#SBATCH -t 1-12
#SBATCH --cpus-per-task=16
#SBATCH --mem=128gb
#SBATCH -o ./AFNI_%j.out
#SBATCH -e ./AFNI_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ws1011001@gmail.com
#SBATCH --mail-type=BEGIN,END

# setup path
idir='/scratch/swang/simages'     # singularity images directory
mdir='/scratch/swang/agora/CP00'  # the project main directory
scripts='/CP00/scripts'           # scripts folder in Sy

# processing log
## 2020-12-27T14:30
#echo -e 'Running ps02_GLM_LocaVis1p75_wNR50_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNR50_afni.sh
## 2020-12-27T18:23
#echo -e 'Running ps02_GLM_LocaVis1p75_wNRmin_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNRmin_afni.sh
# 2020-12-29T09:45
echo -e 'Running ps02_GLM_LocaVis1p75_wNR12_afni.sh with singularity'
singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNR12_afni.sh
