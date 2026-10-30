#!/bin/bash
# Extract ~20 Hz NE dF/F for the 14 mouse-sessions of the 48-h study (v2 method, whole ~48 h).
# Tanks are read from ../48H_GLU_FP and ../48H_SAL_FP. Output: outputs/ne_48h_ds20/.
# Submit from the repo root:
#   mkdir -p outputs/logs && sbatch extraction/run_extract_ne_48h.sbatch
#SBATCH --job-name=extract_ne_48h
#SBATCH --partition=standard
#SBATCH --account=dkell12_lab
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --output=outputs/logs/extract_ne_48h_%j.log

set -euo pipefail
module load git/2.50.1 2>/dev/null || module load git/2.30.1
module load matlab
cd "$SLURM_SUBMIT_DIR"
matlab -nodisplay -batch "addpath('extraction'); extract_ne_48h"
