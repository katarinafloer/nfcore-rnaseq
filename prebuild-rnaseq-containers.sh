#!/bin/bash
#SBATCH --job-name=prebuild-rnaseq-containers
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/prebuild-rnaseq-containers.%j.out
#SBATCH --error=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/prebuild-rnaseq-containers.%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

CACHE_BASE=/work/pi_lmangiamele_smith_edu/nfcore_container_cache
NXF_CACHE="$CACHE_BASE/rnaseq-3.26.0"
BUILD_CACHE="$CACHE_BASE/apptainer-build-cache"
TMP_CACHE="$CACHE_BASE/apptainer-tmp"

mkdir -p "$NXF_CACHE" "$BUILD_CACHE" "$TMP_CACHE"

module purge
module load nextflow/26.04.1
module load apptainer/latest

export APPTAINER_CACHEDIR="$BUILD_CACHE"
export APPTAINER_TMPDIR="$TMP_CACHE"
export PROOT_TMP_DIR="$TMP_CACHE"
export TMPDIR="$TMP_CACHE"
export NXF_APPTAINER_CACHEDIR="$NXF_CACHE"
export NXF_OPTS='-Xms1g -Xmx4g'
export PROOT_NO_SECCOMP=1

echo "Running on host: $(hostname)"
echo "Started at: $(date)"
echo "Container cache: $NXF_APPTAINER_CACHEDIR"

echo "Cleaning partial pulls and invalid images..."
find "$NXF_APPTAINER_CACHEDIR" -type f -name "*.pulling.*" -delete || true
find "$NXF_APPTAINER_CACHEDIR" -type f -name "*.img" | while read -r img; do
    if ! apptainer inspect "$img" > /dev/null 2>&1; then
        echo "Removing invalid image: $img"
        rm -f "$img"
    fi
done

echo "Prebuilding containers by running nf-core/rnaseq test profile..."
cd /work/pi_lmangiamele_smith_edu/nfcore_container_cache

nextflow run nf-core/rnaseq \
  -r 3.26.0 \
  -profile test,unity \
  --outdir prebuild_test_results \
  -resume

echo "Finished at: $(date)"
