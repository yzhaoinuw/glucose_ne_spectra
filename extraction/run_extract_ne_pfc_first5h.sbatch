#!/bin/bash
# Extract ~20 Hz PFC NE dF/F on the first 5 h of the 9 cohort sessions (v2 method, whole-window fit).
# Submit from the repo root:
#   mkdir -p outputs/logs && sbatch extraction/run_extract_ne_pfc_first5h.sbatch
#SBATCH --job-name=extract_ne_pfc_first5h
#SBATCH --partition=standard
#SBATCH --account=dkell12_lab
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --output=outputs/logs/extract_ne_pfc_first5h_%j.log

set -euo pipefail
module load git/2.50.1 2>/dev/null || module load git/2.30.1
module load matlab
cd "$SLURM_SUBMIT_DIR"
matlab -nodisplay -batch "addpath('extraction'); extract_ne_pfc_first5h"
