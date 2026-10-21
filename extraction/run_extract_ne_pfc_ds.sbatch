#!/bin/bash
# Extract downsampled (~20 Hz) PFC NE dF/F (v2: robust, segment-anchored fit) for all usable recordings.
# Submit from the repo root:
#   mkdir -p outputs/logs && sbatch extraction/run_extract_ne_pfc_ds.sbatch
#SBATCH --job-name=extract_ne_pfc_ds
#SBATCH --partition=standard
#SBATCH --account=dkell12_lab
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --output=outputs/logs/extract_ne_pfc_ds_%j.log

set -euo pipefail
module load git/2.30.1
module load matlab
cd "$SLURM_SUBMIT_DIR"
matlab -nodisplay -batch "addpath('extraction'); extract_ne_pfc_ds"
