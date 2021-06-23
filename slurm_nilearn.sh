#!/bin/bash

#SBATCH -J MVPA
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A b222
#SBATCH -t 1-12
#SBATCH --cpus-per-task=32
#SBATCH --mem=160gb
#SBATCH -o ./run_slurm.log/nilearn_%j.out
#SBATCH -e ./run_slurm.log/nilearn_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ws1011001@gmail.com
#SBATCH --mail-type=BEGIN,END

# set an array of scripts
scripts_ni[0]='ps17_MVPA_classifier_selection_nilearn.py'
scripts_ni[1]='ps18_MVPA_AudioVisAssos1word_ROI_classification_nilearn.py'
script_id=1

# run nilearn script
script_run=${scripts_ni[$script_id]}
ni_log="$mdir/scripts/run_nilearn.log"  # records of running nilearn scripts with slurm
SECONDS=0
echo -e "========== Start running $script_run with slurm at $(date) =========="
echo -e "$(date) : $script_run" >> $ni_log
conda run --name base python $script_run
echo -e "========== Finish $script_run with slurm at $(date) =========="
duration=$SECONDS
echo -e "$(date) : $script_run - $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed." >> $ni_log
