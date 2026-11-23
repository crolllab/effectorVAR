// SPAdes memory limit (-m). SPAdes enforces -m on its address space, not on the
// memory it actually uses (RSS). Its memory-mapped temporary files count towards
// the address space, which can reach twice the RSS, so with -m equal to the task
// memory SPAdes stops with ENOMEM at half of it. -m is therefore twice the task
// memory; the SLURM memory limit (or the machine) then bounds the real use, and an
// out-of-memory kill is retried with more memory. Memory, retries and the retry
// policy are set in nextflow.config.

process SPAdes {
    tag "SPAdes PE assembly"

    publishDir "${params.outdir}/2_assemblies", mode: 'copy', pattern: "*/contigs.fasta"
    publishDir "${params.outdir}/2_assemblies", mode: 'copy', pattern: "*/scaffolds.fasta"
    publishDir "${params.outdir}/2_assemblies", mode: 'copy', pattern: "*/spades.log"
    
    input:
    tuple val(sample_id), path(read1), path(read2), val(source)
    
    output:
    tuple val(sample_id), path("${sample_id}/contigs.fasta"), emit: contigs
    tuple val(sample_id), path("${sample_id}/scaffolds.fasta"), emit: scaffolds
    path "${sample_id}/spades.log", emit: log
    
    script:
    """
    spades.py \
        --pe1-1 ${read1} \
        --pe1-2 ${read2} \
        -o ${sample_id} \
        -t ${task.cpus} \
        -m ${task.memory.toGiga() * 2} \
        --isolate
    
    # Clean up intermediate files to save space
    if [ -d "${sample_id}/K21" ]; then
        rm -rf ${sample_id}/K*/
    fi
    if [ -d "${sample_id}/corrected" ]; then
        rm -rf ${sample_id}/corrected/
    fi
    if [ -d "${sample_id}/tmp" ]; then
        rm -rf ${sample_id}/tmp/
    fi
    
    # The staged input reads are deliberately NOT deleted here: resolving the
    # symlink and removing its target destroys the upstream download task's
    # cached output, which breaks -resume and any later retry of this task.
    # Reclaim space with `nextflow clean` after a successful run.
    """
}

// SPAdes process for single-end reads
process SPAdesSE {
    tag "SPAdes SE assembly"

    publishDir "${params.outdir}/2_assemblies", mode: 'copy', pattern: "*/contigs.fasta"
    publishDir "${params.outdir}/2_assemblies", mode: 'copy', pattern: "*/scaffolds.fasta"
    publishDir "${params.outdir}/2_assemblies", mode: 'copy', pattern: "*/spades.log"
    
    input:
    tuple val(sample_id), path(read), val(source)
    
    output:
    tuple val(sample_id), path("${sample_id}/contigs.fasta"), emit: contigs
    tuple val(sample_id), path("${sample_id}/scaffolds.fasta"), emit: scaffolds
    path "${sample_id}/spades.log", emit: log
    
    script:
    """
    spades.py \
        --s1 ${read} \
        -o ${sample_id} \
        -t ${task.cpus} \
        -m ${task.memory.toGiga() * 2} \
        --isolate
    
    # Clean up intermediate files to save space
    if [ -d "${sample_id}/K21" ]; then
        rm -rf ${sample_id}/K*/
    fi
    if [ -d "${sample_id}/corrected" ]; then
        rm -rf ${sample_id}/corrected/
    fi
    if [ -d "${sample_id}/tmp" ]; then
        rm -rf ${sample_id}/tmp/
    fi
    
    # The staged input read is deliberately NOT deleted here: resolving the
    # symlink and removing its target destroys the upstream download task's
    # cached output, which breaks -resume and any later retry of this task.
    # Reclaim space with `nextflow clean` after a successful run.
    """
}

