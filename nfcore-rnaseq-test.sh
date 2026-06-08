#!/bin/bash
#SBATCH --job-name=nfcore-rnaseq-test
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/nfcore-rnaseq-test.%j.out
#SBATCH --error=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/nfcore-rnaseq-test.%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

SCRATCH_RNASEQ=/scratch4/workspace/kfloer_smith_edu-rnaseq_t2

echo "Running on host: $(hostname)"
echo "Started at: $(date)"
echo "Scratch workspace: $SCRATCH_RNASEQ"

cd "$SCRATCH_RNASEQ"

module purge
module load nextflow/26.04.1
module load apptainer/latest

mkdir -p "$SCRATCH_RNASEQ/.apptainer/build-cache"
mkdir -p "$SCRATCH_RNASEQ/.apptainer/tmp"
mkdir -p "$SCRATCH_RNASEQ/.nextflow-apptainer-cache"

export APPTAINER_CACHEDIR="$SCRATCH_RNASEQ/.apptainer/build-cache"
export APPTAINER_TMPDIR="$SCRATCH_RNASEQ/.apptainer/tmp"
export NXF_APPTAINER_CACHEDIR="$SCRATCH_RNASEQ/.nextflow-apptainer-cache"
export NXF_OPTS='-Xms1g -Xmx4g'
export PROOT_NO_SECCOMP=1

echo "Cleaning partial Apptainer pulls..."
find "$NXF_APPTAINER_CACHEDIR" -type f -name "*.pulling.*" -delete || true

echo "Checking cached Apptainer images..."
find "$NXF_APPTAINER_CACHEDIR" -type f -name "*.img" | while read -r img; do
    if ! apptainer inspect "$img" > /dev/null 2>&1; then
        echo "Removing invalid container image: $img"
        rm -f "$img"
    fi
done

echo "Launching nf-core/rnaseq test pipeline..."
nextflow run nf-core/rnaseq \
  -r 3.26.0 \
  -profile test,unity \
  --outdir test_results \
  -resume

echo "Finished at: $(date)"
