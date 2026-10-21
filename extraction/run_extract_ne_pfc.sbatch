#!/bin/bash
# Extract full-rate PFC NE dF/F for all usable recordings.
# Submit from the repo root:
#   mkdir -p outputs/logs && sbatch extraction/run_extract_ne_pfc.sbatch
#SBATCH --job-name=extract_ne_pfc
#SBATCH --partition=standard
#SBATCH --account=dkell12_lab
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --output=outputs/logs/extract_ne_pfc_%j.log

set -euo pipefail
module load git/2.30.1
module load matlab
cd "$SLURM_SUBMIT_DIR"
matlab -nodisplay -batch "addpath('extraction'); extract_ne_pfc"
