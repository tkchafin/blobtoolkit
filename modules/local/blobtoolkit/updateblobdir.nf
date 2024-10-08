process BLOBTOOLKIT_UPDATEBLOBDIR {
    tag "$meta.id"
    label 'process_medium'

    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "BLOBTOOLKIT_BLOBDIR module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    container "docker.io/genomehubs/blobtoolkit:4.3.9"

    input:
    tuple val(meta), path(input, stageAs: "input_blobdir")
    tuple val(meta1), path(blastx, stageAs: "blastx.txt")
    tuple val(meta2), path(blastn, stageAs: "blastn.txt")
    path(taxdump)

    output:
    tuple val(meta), path(prefix), emit: blobdir
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def hits_blastx = blastx ? "--hits ${blastx}" : ""
    def hits_blastn = blastn ? "--hits ${blastn}" : ""
    """
    # In-place modifications are not great in Nextflow, so work on a copy of ${input}
    mkdir ${prefix}
    cp --preserve=timestamp ${input}/* ${prefix}/
    blobtools replace \\
        --taxdump ${taxdump} \\
        --taxrule bestdistorder=buscoregions \\
        ${hits_blastx} \\
        ${hits_blastn} \\
        --threads ${task.cpus} \\
        $args \\
        ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blobtoolkit: \$(btk --version | cut -d' ' -f2 | sed 's/v//')
    END_VERSIONS
    """
}
