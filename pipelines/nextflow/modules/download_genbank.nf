#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process download_genbank {
    label "Sequence_genbank_file"
    tag "${accession}"
    label 'default'

    input:
        val accession

    output:
       path "*.gb"

    script:
    """
    download_genbank --accession ${accession}
    """
}
