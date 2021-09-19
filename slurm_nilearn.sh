#!/bin/bash

#SBATCH -J tvrMVPA
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A b222
#SBATCH -t 3-12
#SBATCH --cpus-per-task=16
#SBATCH --mem=128gb
#SBATCH -o ./run_slurm.log/nilearn_%j.out
#SBATCH -e ./run_slurm.log/nilearn_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=shuai.wang.notes@gmail.com
#SBATCH --mail-type=BEGIN,END

# set an array of scripts
scripts_ni[0]='ps19_MVPA_classifier_selection_nilearn.py'
scripts_ni[1]='ps20_MVPA_AudioVisAssos1word_ROI_classification_nilearn.py'
scripts_ni[2]='ps21_MVPA_AudioVisAssos1word_searchlight_classification_nilearn.py'
script_id=0

# run nilearn script
script_run=${scripts_ni[$script_id]}
ni_log='run_nilearn.log'  # records of running nilearn scripts with slurm
SECONDS=0
echo -e "========== Start running $script_run with slurm at $(date) =========="
echo -e "$(date) : $script_run" >> $ni_log
conda run --name base python $script_run
echo -e "========== Finish $script_run with slurm at $(date) =========="
duration=$SECONDS
echo -e "$(date) : $script_run - $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed." >> $ni_log
