#!/bin/bash

#SBATCH -J AFNI
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A b222
#SBATCH -t 1-12
#SBATCH --cpus-per-task=16
#SBATCH --mem=128gb
#SBATCH -o ./run_slurm.log/AFNI_%j.out
#SBATCH -e ./run_slurm.log/AFNI_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ws1011001@gmail.com
#SBATCH --mail-type=BEGIN,END

# setup path
idir='/home/swang/simages'        # singularity images directory
mdir='/scratch/swang/agora/CP00'  # the project main directory
scripts='/CP00/scripts'           # scripts folder in Sy

# set an array of scripts 
scripts_afni[0]='ps00_DATA_stimuli_timings_afni.sh'
scripts_afni[1]='ps05_GLM_LocaVis1p75_wPSC_wNR14_afni.sh'
scripts_afni[2]='ps06_GLM_LocaVis1p75_wPSC_wNR24a_afni.sh'  # scale + 12 motion + 6 first WM + 6 first CSF + highpass 128s
scripts_afni[3]='ps07_STAT_LocaVis1p75_ttests_afni.sh'
script_id=0

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
