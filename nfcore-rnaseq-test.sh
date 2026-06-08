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
hostname
date

SCRATCH_RNASEQ=/scratch4/workspace/kfloer_smith_edu-rnaseq_tutorial

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

nextflow run nf-core/rnaseq \
  -r 3.26.0 \
  -profile test,unity \
  --outdir test_results \
  -resume
