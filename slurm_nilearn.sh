#!/bin/bash

#SBATCH -J MVPA
#SBATCH -p skylake
#SBATCH --nodes=1
#SBATCH -A a222
#SBATCH -t 1-12
#SBATCH --cpus-per-task=16
#SBATCH --mem=128gb
#SBATCH -o ./nilearn_%j.out
#SBATCH -e ./nilearn_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ws1011001@gmail.com
#SBATCH --mail-type=BEGIN,END

# processing log
echo "========== Satrt running ps14_MVPA_AudioVisAssos1word_searchlight_nilearn.py at $(date) =========="
conda run --name base python ps14_MVPA_AudioVisAssos1word_searchlight_nilearn.py
echo "========== Finish ps14_MVPA_AudioVisAssos1word_searchlight_nilearn.py at $(date) =========="
