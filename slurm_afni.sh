#!/bin/bash

#SBATCH -J AFNI
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A b222
#SBATCH -t 1-12
#SBATCH --cpus-per-task=16
#SBATCH --mem=128gb
#SBATCH -o ./AFNI_%j.out
#SBATCH -e ./AFNI_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ws1011001@gmail.com
#SBATCH --mail-type=BEGIN,END

# setup path
idir='/home/swang/simages'        # singularity images directory
mdir='/scratch/swang/agora/CP00'  # the project main directory
scripts='/CP00/scripts'           # scripts folder in Sy
afni_log="$scripts/run_AFNI.log"  # records of running AFNI scripts with slurm

# set an array of scripts 
scripts_afni=("ps05_GLM_LocaVis1p75_wPSC_wNR14_afni.sh")
script_run=${scripts_afni[0]}

# run AFNI script
echo -e "========== Start running $script_run with singularity at $(date) ==========" >> $afni_log
singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/$script_run
echo -e "========== Finish $script_run with singularity at $(date) ==========" >> $afni_log

#echo -e "========== Start running ps00_DATA_stimuli_timings_afni.sh with singularity at $(date) =========="
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps07_STAT_LocaVis1p75_ttests_afni.sh
#echo -e "========== Finish ps00_DATA_stimuli_timings_afni.sh with singularity at $(date) =========="

#echo -e 'Running ps02_GLM_LocaVis1p75_wNR50_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNR50_afni.sh

#echo -e 'Running ps02_GLM_LocaVis1p75_wNRmin_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNRmin_afni.sh

#echo -e 'Running ps02_GLM_LocaVis1p75_wNR12_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNR12_afni.sh

#echo -e 'Running ps02_GLM_LocaVis1p75_wNR14_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaVis1p75_wNR14_afni.sh



#echo -e "========== Start running ps07_STAT_LocaVis1p75_ttests_afni.sh with singularity at $(date) =========="
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps07_STAT_LocaVis1p75_ttests_afni.sh
#echo -e "========== Finish ps07_STAT_LocaVis1p75_ttests_afni.sh with singularity at $(date) =========="

#echo -e 'Running ps02_GLM_LocaAudio2p5_wNR14.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps02_GLM_LocaAudio2p5_wNR14.sh

#echo -e 'Running ps08_GLM_AudioVisAssos1word_wNR14_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps08_GLM_AudioVisAssos1word_wNR14_afni.sh

#echo -e 'Running ps09_GLM_AudioVisAssos1word_wPSC_wNR14_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps09_GLM_AudioVisAssos1word_wPSC_wNR14_afni.sh

#echo -e 'Running ps10_GLM_AudioVisAssos2words_wPSC_wNR14_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps10_GLM_AudioVisAssos2words_wPSC_wNR14_afni.sh

#echo -e "========== Start running ps11_GLM_AudioVisAssos2words_wPSC_wTENT_wNR14_afni.sh with singularity at $(date) =========="
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps11_GLM_AudioVisAssos2words_wPSC_wTENT_wNR14_afni.sh
#echo -e "========== Finish ps11_GLM_AudioVisAssos2words_wPSC_wTENT_wNR14_afni.sh with singularity at $(date) =========="

#echo -e 'Running ps12_LSS_AudioVisAssos1word_wPSC_wNR14_afni.sh with singularity'
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps12_LSS_AudioVisAssos1word_wPSC_wNR14_afni.sh

#echo -e "========== Start running ps13_LSS_AudioVisAssos1word_estimates_afni.sh with singularity at $(date) =========="
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/ps13_LSS_AudioVisAssos1word_estimates_afni.sh
#echo -e "========== Finish ps13_LSS_AudioVisAssos1word_estimates_afni.sh with singularity at $(date) =========="

#echo -e "========== Start running psmeta_individual_and_group_masks_afni.sh with singularity at $(date) =========="
#singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/psmeta_individual_and_group_masks_afni.sh
#echo -e "========== Finish psmeta_individual_and_group_masks_afni.sh with singularity at $(date) =========="
