// Based on the EXTRACT_BUSCO_GENES module

process COUNT_BUSCO_GENES {
    tag "$meta.id"
    label 'process_single'

    container "genomehubs/blobtoolkit-blobtools:3.4.2"

    input:
    tuple val(meta), path(tsv, stageAs: 'dir??/*')  //full table tsv files from Busco
    tuple val(meta), path(bed)  //modified fasta windows bed file

    output:
    tuple val(meta), path('*_busco_genes_count.tsv') , emit: tsv
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def busco_inputs = tsv.collect{"--in $it"}.join(' ')

    """
    btk pipeline count-busco-genes \\
            $busco_inputs \\
            --mask ${bed} \\
            --out ${prefix}_busco_genes_count.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blobtoolkit: \$(btk --version | cut -d' ' -f2 | sed 's/v//')
    END_VERSIONS
    """
}
