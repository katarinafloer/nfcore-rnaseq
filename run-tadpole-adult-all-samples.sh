#!/bin/bash
#SBATCH --job-name=nfcore-rnaseq-tadpole-adult-all
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --time=3-00:00:00
#SBATCH --output=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/nfcore-rnaseq-tadpole-adult-all.%j.out
#SBATCH --error=/home/kfloer_smith_edu/rnaseq_nf_core/job-logs/nfcore-rnaseq-tadpole-adult-all.%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=kfloer@smith.edu

set -euo pipefail

SCRATCH_RNASEQ=/scratch/workspace/kfloer_smith_edu-rnaseq_tadpole_adult_all
SHARED_CONTAINER_CACHE=/work/pi_lmangiamele_smith_edu/nfcore_container_cache/rnaseq-3.26.0

FASTQ_DIR=/work/pi_lmangiamele_smith_edu/03_26_flut_yale_rnaseq

GENOME_DIR=/scratch3/workspace/kfloer_smith_edu-simple/egapx_sparvus/output_tadpole_plus_adult
GENOME_FASTA="$GENOME_DIR/complete.genomic.fna"
GENOME_GTF="$GENOME_DIR/complete.genomic.gtf"

SAMPLESHEET="$SCRATCH_RNASEQ/samplesheets/sparvus_all_samples_tadpole_adult.csv"
PARAMS="$SCRATCH_RNASEQ/tadpole_adult_all_samples_params.json"
OUTDIR="$SCRATCH_RNASEQ/results_sparvus_tadpole_adult_all_samples"

echo "Running on host: $(hostname)"
echo "Started at: $(date)"
echo "Scratch workspace: $SCRATCH_RNASEQ"
echo "Shared container cache: $SHARED_CONTAINER_CACHE"
echo "FASTQ directory: $FASTQ_DIR"
echo "Genome FASTA: $GENOME_FASTA"
echo "Genome GTF: $GENOME_GTF"
echo "Output directory: $OUTDIR"

cd "$SCRATCH_RNASEQ"

module purge
module load nextflow/26.04.1
module load apptainer/latest

mkdir -p "$SCRATCH_RNASEQ/.apptainer/build-cache"
mkdir -p "$SCRATCH_RNASEQ/.apptainer/tmp"
mkdir -p "$SCRATCH_RNASEQ/samplesheets"
mkdir -p /home/kfloer_smith_edu/rnaseq_nf_core/job-logs

export APPTAINER_CACHEDIR="$SCRATCH_RNASEQ/.apptainer/build-cache"
export APPTAINER_TMPDIR="$SCRATCH_RNASEQ/.apptainer/tmp"
export PROOT_TMP_DIR="$SCRATCH_RNASEQ/.apptainer/tmp"
export TMPDIR="$SCRATCH_RNASEQ/.apptainer/tmp"
export NXF_APPTAINER_CACHEDIR="$SHARED_CONTAINER_CACHE"
export NXF_OPTS='-Xms1g -Xmx4g'
export PROOT_NO_SECCOMP=1

echo "Checking required directories..."
for d in "$SCRATCH_RNASEQ" "$FASTQ_DIR" "$GENOME_DIR" "$SHARED_CONTAINER_CACHE"; do
    if [[ ! -d "$d" ]]; then
        echo "ERROR: Missing directory: $d"
        exit 1
    fi
done

echo "Checking genome files..."
for f in "$GENOME_FASTA" "$GENOME_GTF"; do
    if [[ ! -s "$f" ]]; then
        echo "ERROR: Missing or empty genome file: $f"
        exit 1
    fi
done

echo "Writing samplesheet from all FASTQ pairs..."
echo "sample,fastq_1,fastq_2,strandedness" > "$SAMPLESHEET"

shopt -s nullglob
r1_files=("$FASTQ_DIR"/*_R1_001.fastq.gz)

if [[ ${#r1_files[@]} -eq 0 ]]; then
    echo "ERROR: No R1 FASTQ files found in $FASTQ_DIR"
    exit 1
fi

for r1 in "${r1_files[@]}"; do
    sample=$(basename "$r1" _R1_001.fastq.gz)
    r2="$FASTQ_DIR/${sample}_R2_001.fastq.gz"

    if [[ ! -s "$r2" ]]; then
        echo "ERROR: Missing R2 for sample $sample: $r2"
        exit 1
    fi

    echo "${sample},${r1},${r2},reverse" >> "$SAMPLESHEET"
done

echo "Samplesheet:"
cat "$SAMPLESHEET"

echo "Number of samples:"
tail -n +2 "$SAMPLESHEET" | wc -l

echo "Writing params file..."
cat > "$PARAMS" <<EOF
{
  "input": "$SAMPLESHEET",
  "outdir": "$OUTDIR",
  "fasta": "$GENOME_FASTA",
  "gtf": "$GENOME_GTF",
  "igenomes_ignore": true,
  "aligner": "star_salmon",
  "pseudo_aligner": "salmon",
  "gtf_extra_attributes": "gene",
  "featurecounts_group_type": "transcript_biotype",
  "max_cpus": 48,
  "max_memory": "256.GB",
  "max_time": "72.h"
}
EOF

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

echo "Launching nf-core/rnaseq with all samples and tadpole+adult genome..."
nextflow run nf-core/rnaseq \
  -r 3.26.0 \
  -profile unity \
  -params-file "$PARAMS" \
  -resume

echo "Finished at: $(date)"
