#!/usr/bin/env nextflow
// See the NOTICE file distributed with this work for additional information
// regarding copyright ownership.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Genome prepare pipeline
// See full documentation in docs/genome_prepare.md

// Print usage
def helpMessage() {
  log.info """
        Usage:
        The typical command for running the 'Genome prepare' pipeline is as follows:

        nextflow run workflows/genome_prepare/main.nf --input_dir <json_input_dir>

        Mandatory arguments:
        --input_dir                    Location of input json(s) with component/organism genome metadata

        Optional arguments:
        --help                         This usage statement.
        """
}

// Check mandatory parameters
if (params.help) {
    helpMessage()
    exit 0
}



// Import modules/subworkflows
include { CHECK_JSON_SCHEMA as CHECK_JSON_SCHEMA_GENOME } from '../../modules/check_json_schema.nf'
include { CHECK_JSON_SCHEMA as CHECK_JSON_SCHEMA_SEQREG } from '../../modules/check_json_schema.nf'
include { CHECK_JSON_SCHEMA as CHECK_JSON_SCHEMA_FUNCT } from '../../modules/check_json_schema.nf'
include { DOWNLOAD_ASM_DATA } from '../../modules/download_asm_data.nf'
include { UNPACK_FILE } from '../../modules/unpack_gff3.nf'
include { PROCESS_GFF3 } from '../../modules/process_gff3.nf'
include { GFF3_VALIDATION } from '../../modules/gff3_validation.nf'
include { PROCESS_SEQ_REGION } from '../../modules/process_seq_region.nf'
include { PROCESS_FASTA as PROCESS_FASTA_DNA } from '../../modules/process_fasta_data.nf'
include { PROCESS_FASTA as PROCESS_FASTA_PEP } from '../../modules/process_fasta_data.nf'
include { AMEND_GENOME_DATA } from '../../modules/amend_genome_data.nf'
include { COLLECT_FILES; MANIFEST; PUBLISH_DIR } from '../../modules/collect_files.nf'
include { CHECK_INTEGRITY } from '../../modules/integrity.nf'
include { MANIFEST_STATS } from '../../modules/manifest_stats.nf'


// Run main workflow
workflow GENOME_PREPARE {

    take:
        accession
        genome_json
        output_dir

    main:
        CHECK_JSON_SCHEMA_GENOME(genome_json, accession)
        DOWNLOAD_ASM_DATA(CHECK_JSON_SCHEMA_GENOME.out.gca)

        if (DOWNLOAD_ASM_DATA.out.gene_gff && DOWNLOAD_ASM_DATA.out.protein_fa) {
            UNPACK_FILE(DOWNLOAD_ASM_DATA.out.gene_gff, 'gff', DOWNLOAD_ASM_DATA.out.gca)

            PROCESS_GFF3(UNPACK_FILE.out.uncompressed_file, CHECK_JSON_SCHEMA_GENOME.out.verified_json, UNPACK_FILE.out.gca)

            CHECK_JSON_SCHEMA_FUNCT(PROCESS_GFF3.out.functional_annotation, PROCESS_GFF3.out.gca)

            GFF3_VALIDATION(PROCESS_GFF3.out.gene_models)

            PROCESS_FASTA_PEP(DOWNLOAD_ASM_DATA.out.protein_fa, DOWNLOAD_ASM_DATA.out.genome_gbff, DOWNLOAD_ASM_DATA.out.gca, '1')
        }

        PROCESS_SEQ_REGION(CHECK_JSON_SCHEMA_GENOME.out.verified_json, DOWNLOAD_ASM_DATA.out.asm_report, DOWNLOAD_ASM_DATA.out.genome_gbff, DOWNLOAD_ASM_DATA.out.gca)
        CHECK_JSON_SCHEMA_SEQREG(PROCESS_SEQ_REGION.out.seq_region, PROCESS_SEQ_REGION.out.gca)

        PROCESS_FASTA_DNA(DOWNLOAD_ASM_DATA.out.genome_fna, DOWNLOAD_ASM_DATA.out.genome_gbff, DOWNLOAD_ASM_DATA.out.gca, '0')

        AMEND_GENOME_DATA(CHECK_JSON_SCHEMA_GENOME.out.verified_json, DOWNLOAD_ASM_DATA.out.asm_report, DOWNLOAD_ASM_DATA.out.genome_gbff, DOWNLOAD_ASM_DATA.out.gca, params.brc4_mode)
        amended_json = AMEND_GENOME_DATA.out.amended_json
        // amended_json.view()

        // Group files
        // prepared_files = CHECK_JSON_SCHEMA_GENOME.out.verified_json
        //             .concat(PROCESS_GFF3.out.gene_models, CHECK_JSON_SCHEMA_FUNCT.out.verified_json,
        //             PROCESS_FASTA_PEP.out.processed_fasta, CHECK_JSON_SCHEMA_SEQREG.out.verified_json,
        //             PROCESS_FASTA_DNA.out.processed_fasta)
        //             .map{it -> [accession, it]}
        //             .groupTuple()

        // // Collect in manifest, checks and stats
        // collect_dir = COLLECT_FILES(prepared_files)
        // manifest_dired = MANIFEST(collect_dir, accession)
        // manifest_checked = CHECK_INTEGRITY(manifest_dired, params.brc4_mode)
        // manifest_stated = MANIFEST_STATS(manifest_checked, 'datasets')

        // // Publish the data
        // PUBLISH_DIR(manifest_stated, output_dir, accession)
}