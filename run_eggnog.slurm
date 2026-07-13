#!/bin/bash
#SBATCH --job-name=eggnog_sparvus
#SBATCH --output=eggnog_sparvus_%j.out
#SBATCH --error=eggnog_sparvus_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G

set -euo pipefail

module purge
module load uri/main
module load eggnog-mapper/2.1.12-foss-2023a

cd /scratch3/workspace/kfloer_smith_edu-simple/egapx_sparvus/output_tadpole_plus_adult

mkdir -p eggnog_annotation

echo "Job started: $(date)"
echo "Node: $(hostname)"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Proteins: $(grep -c '^>' complete.proteins.faa)"

emapper.py \
  -i complete.proteins.faa \
  --itype proteins \
  --output sparvus_egapx \
  --output_dir eggnog_annotation \
  --cpu "${SLURM_CPUS_PER_TASK}" \
  --override

echo "Job completed: $(date)"
