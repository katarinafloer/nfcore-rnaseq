#!/bin/bash
#SBATCH --job-name=nfcore-rnaseq-test
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/nfcore-rnaseq-demo.%j.out
#SBATCH --error=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/nfcore-rnaseq-demo.%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu


set -euo pipefail

SCRATCH_RUN=/scratch4/workspace/kfloer_smith_edu-rnaseq_demo

cd "$SCRATCH_RUN"

module purge
module load nextflow/26.04.1
module load apptainer/latest

mkdir -p "$SCRATCH_RUN/.apptainer/build-cache"
mkdir -p "$SCRATCH_RUN/.apptainer/tmp"
mkdir -p "$SCRATCH_RUN/.nextflow-apptainer-cache"

export APPTAINER_CACHEDIR="$SCRATCH_RUN/.apptainer/build-cache"
export APPTAINER_TMPDIR="$SCRATCH_RUN/.apptainer/tmp"
export NXF_APPTAINER_CACHEDIR="$SCRATCH_RUN/.nextflow-apptainer-cache"
export NXF_OPTS='-Xms1g -Xmx4g'
export PROOT_NO_SECCOMP=1

nextflow run nf-core/demo \
  -profile test,unity \
  --outdir demo_results \
  -resume
