#!/bin/bash

#SBATCH -J AFNI
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A b222
#SBATCH -t 6-12
#SBATCH --cpus-per-task=8
#SBATCH --mem=32gb
#SBATCH -o ./run_slurm.log/AFNI_%j.out
#SBATCH -e ./run_slurm.log/AFNI_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=shuai.wang.notes@gmail.com
#SBATCH --mail-type=BEGIN,END

# setup path
idir='/home/swang/simages'        # singularity images directory
mdir='/scratch/swang/agora/CP00'  # the project main directory
scripts='/CP00/scripts'           # scripts folder in Sy

# set an array of scripts 
scripts_afni[0]='ps00_DATA_stimuli_timings_afni.sh'
scripts_afni[1]='ps03_GLM_LocaVis1p75_wNRmin_afni.sh'
scripts_afni[2]='ps05_GLM_LocaVis1p75_wPSC_wNR14_afni.sh'
scripts_afni[3]='ps06_GLM_LocaVis1p75_wPSC_wNR24a_afni.sh'  # scale + 12 motion + 6 first WM + 6 first CSF + highpass 128s
scripts_afni[4]='ps07_GLM_LocaVis1p75_wBIM_wPSC_wNR24a_afni.sh'
scripts_afni[5]='ps08_STAT_LocaVis1p75_ttests_afni.sh'
scripts_afni[6]='ps08_GLM_LocaAudio2p5_wPSC_wNR24a_afni.sh'
scripts_afni[7]='ps09_GLM_LocaAudio2p5_wPSC_wNR48_afni.sh'
scripts_afni[8]='ps11_STAT_LocaAudio2p5_ttests_afni.sh'
scripts_afni[9]='ps12_GLM_AudioVisAssos1word_wBIM_wPSC_wNR24a_afni.sh'
scripts_afni[10]='ps13_LSS_AudioVisAssos1word_wPSC_wNR24a_afni.sh'
scripts_afni[11]='ps14_LSS_AudioVisAssos1word_estimates_afni.sh'
scripts_afni[12]='ps15_GLM_AudioVisAssos2words_wBIM_wPSC_wNR24a_afni.sh'
scripts_afni[13]='ps16_GLM_AudioVisAssos2words_wBIM_wPSC_wTENT_wNR24a_afni.sh'
scripts_afni[14]='ps17_STAT_AudioVisAssos1word_factorial_afni.sh'
scripts_afni[15]='ps22_STAT_AudioVisAssos1word_searchlight_ACC_afni.sh'
scripts_afni[16]='ps26_STAT_AudioVisAssos1word_searchlight_RSA_afni.sh'
scripts_afni[17]='ps27_RSE_AudioVisAssos2words_extract_PSC_and_TENT_afni.sh'
scripts_afni[18]='ps28_CONN_LocaAudio2p5_gPPI_afni.sh'
scripts_afni[19]='ps29_STAT_LocaAudio2p5_gPPI_ttests_afni.sh'
scripts_afni[20]='psmeta_individual_and_group_masks_afni.sh'
script_id=17

# run AFNI script
script_run=${scripts_afni[$script_id]}
afni_log="$mdir/scripts/run_AFNI.log"  # records of running AFNI scripts with slurm
SECONDS=0
echo -e "========== Start running $script_run with singularity at $(date) =========="
echo -e "$(date) : $script_run" >> $afni_log
singularity exec --bind $mdir:/CP00 $idir/nidebian-1.1.2 bash $scripts/$script_run
echo -e "========== Finish $script_run with singularity at $(date) =========="
duration=$SECONDS
echo -e "$(date) : $script_run - $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed." >> $afni_log
