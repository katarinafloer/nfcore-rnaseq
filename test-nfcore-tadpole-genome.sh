#!/bin/bash
#SBATCH --job-name=nfcore-rnaseq-sparvus-test
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --time=24:00:00
#SBATCH --output=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/nfcore-rnaseq-sparvus-test.%j.out
#SBATCH --error=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/nfcore-rnaseq-sparvus-test.%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

SCRATCH_RNASEQ=/scratch/workspace/kfloer_smith_edu-rnaseq_real_test
SHARED_CONTAINER_CACHE=/work/pi_lmangiamele_smith_edu/nfcore_container_cache/rnaseq-3.26.0

GENOME_FASTA=/scratch3/workspace/kfloer_smith_edu-simple/egapx_sparvus/output/complete.genomic.fna
GENOME_GTF=/scratch3/workspace/kfloer_smith_edu-simple/egapx_sparvus/output/complete.genomic.gtf

echo "Running on host: $(hostname)"
echo "Started at: $(date)"
echo "Scratch workspace: $SCRATCH_RNASEQ"
echo "Shared container cache: $SHARED_CONTAINER_CACHE"
echo "Genome FASTA: $GENOME_FASTA"
echo "Genome GTF: $GENOME_GTF"

cd "$SCRATCH_RNASEQ"

module purge
module load nextflow/26.04.1
module load apptainer/latest

mkdir -p "$SCRATCH_RNASEQ/.apptainer/build-cache"
mkdir -p "$SCRATCH_RNASEQ/.apptainer/tmp"
mkdir -p "$SCRATCH_RNASEQ/samplesheets"

export APPTAINER_CACHEDIR="$SCRATCH_RNASEQ/.apptainer/build-cache"
export APPTAINER_TMPDIR="$SCRATCH_RNASEQ/.apptainer/tmp"
export PROOT_TMP_DIR="$SCRATCH_RNASEQ/.apptainer/tmp"
export TMPDIR="$SCRATCH_RNASEQ/.apptainer/tmp"
export NXF_APPTAINER_CACHEDIR="$SHARED_CONTAINER_CACHE"
export NXF_OPTS='-Xms1g -Xmx4g'
export PROOT_NO_SECCOMP=1

echo "Writing samplesheet..."
cat > "$SCRATCH_RNASEQ/samplesheets/sparvus_test_samplesheet.csv" <<EOF
sample,fastq_1,fastq_2,strandedness
C45-1B_S2_L002,/work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq/C45-1B_S2_L002_R1_001.fastq.gz,/work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq/C45-1B_S2_L002_R2_001.fastq.gz,auto
C45-1H_S1_L002,/work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq/C45-1H_S1_L002_R1_001.fastq.gz,/work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq/C45-1H_S1_L002_R2_001.fastq.gz,auto
EOF

echo "Writing params file..."
cat > "$SCRATCH_RNASEQ/tadpole_params.json" <<EOF
{
  "input": "$SCRATCH_RNASEQ/samplesheets/sparvus_test_samplesheet.csv",
  "outdir": "$SCRATCH_RNASEQ/results_sparvus_test",
  "fasta": "$GENOME_FASTA",
  "gtf": "$GENOME_GTF",
  "igenomes_ignore": true,
  "aligner": "star_salmon",
  "pseudo_aligner": "salmon",
  "skip_bbsplit": true,
  "skip_markduplicates": true,
  "skip_rseqc": true,
  "skip_dupradar": true
}
EOF

echo "Checking required input files..."
for f in \
  "$GENOME_FASTA" \
  "$GENOME_GTF" \
  /work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq/C45-1B_S2_L002_R1_001.fastq.gz \
  /work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq/C45-1B_S2_L002_R2_001.fastq.gz \
  /work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq/C45-1H_S1_L002_R1_001.fastq.gz \
  /work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq/C45-1H_S1_L002_R2_001.fastq.gz
do
    if [[ ! -s "$f" ]]; then
        echo "ERROR: Missing or empty file: $f"
        exit 1
    fi
done

echo "Checking shared Apptainer images..."
find "$NXF_APPTAINER_CACHEDIR" -type f -name "*.img" | while read -r img; do
    if ! apptainer inspect "$img" > /dev/null 2>&1; then
        echo "ERROR: Invalid shared container image: $img"
        echo "Ask the cache owner to rebuild the shared cache."
        exit 1
    fi
done

echo "Nextflow version:"
nextflow -version

echo "Apptainer version:"
apptainer --version

echo "Launching nf-core/rnaseq custom genome test..."
nextflow run nf-core/rnaseq \
  -r 3.26.0 \
  -profile unity \
  -params-file "$SCRATCH_RNASEQ/tadpole_params.json" \
  -resume

echo "Finished at: $(date)"
