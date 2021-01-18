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
#echo -e 'Running ps02_GLM_LocaVis1p75_wNR50_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNR50_afni.sh
#echo -e 'Running ps02_GLM_LocaVis1p75_wNRmin_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNRmin_afni.sh
#echo -e 'Running ps02_GLM_LocaVis1p75_wNR12_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNR12_afni.sh
#echo -e 'Running ps02_GLM_LocaVis1p75_wNR14_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNR14_afni.sh
#echo -e 'Running ps02_GLM_LocaAudio2p5_wNR14.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaAudio2p5_wNR14.sh
#echo -e 'Running ps08_GLM_AudioVisAssos1word_wNR14_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps08_GLM_AudioVisAssos1word_wNR14_afni.sh
echo -e 'Running ps09_GLM_AudioVisAssos1word_wPSC_wNR14_afni.sh with singularity'
singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps09_GLM_AudioVisAssos1word_wPSC_wNR14_afni.sh
#echo -e 'Running ps03_GLM_AudioVisAssos2words_wPSC_wNR14_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps03_GLM_AudioVisAssos2words_wPSC_wNR14_afni.sh
#echo -e 'Running ps12_LSS_AudioVisAssos1word_wPSC_wNR14_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps12_LSS_AudioVisAssos1word_wPSC_wNR14_afni.sh
