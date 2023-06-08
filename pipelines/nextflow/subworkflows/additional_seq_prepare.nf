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

// Import modules/subworkflows
include { DOWNLOAD_GENBANK } from '../modules/download_genbank.nf'
include { EXTRACT_FROM_GB } from '../modules/extract_from_gb.nf'
include { PROCESS_GFF3 } from '../modules/process_gff3.nf'
include { GFF3_VALIDATION } from '../modules/gff3_validation.nf'
include { CHECK_JSON_SCHEMA } from '../modules/check_json_schema.nf'
include { COLLECT_FILES } from '../modules/collect_files.nf'
include { MANIFEST } from '../modules/manifest_maker.nf'
include { PUBLISH_DIR } from '../modules/publish_output.nf'
include { CHECK_INTEGRITY } from '../modules/integrity.nf'
include { MANIFEST_STATS } from '../modules/manifest_stats.nf'

workflow additional_seq_prepare {
    take:
        prefix
        accession
        production_name
        brc_mode
        output_dir
    main:
        // Get the data
        gb_file = DOWNLOAD_GENBANK(accession)

        // Parse data from GB file into GFF3 and json files
        EXTRACT_FROM_GB(DOWNLOAD_GENBANK.out.downloaded_gb_data, prefix, production_name)

        PROCESS_GFF3(EXTRACT_FROM_GB.out.gene_gff, EXTRACT_FROM_GB.out.genome)

        // Tidy and validate gff3 using gff3validator (NOTE: Requires `module load libffi-3.3-gcc-9.3.0-cgokng6`)
        GFF3_VALIDATION(PROCESS_GFF3.out.functional_annotation, PROCESS_GFF3.out.gene_models)

        // Validate files
        json_files = EXTRACT_FROM_GB.out.genome
            .concat(EXTRACT_FROM_GB.out.seq_regions, PROCESS_GFF3.out.functional_annotation)
        
        // Verify schemas 
        CHECK_JSON_SCHEMA(json_files)

        // Gather json and fasta files and reduce to unique input accession
        all_files = CHECK_JSON_SCHEMA.out.verified_json
                        .concat(GFF3_VALIDATION.out.gene_models)
                        .concat(EXTRACT_FROM_GB.out.dna_fasta, EXTRACT_FROM_GB.out.pep_fasta)
                        .groupTuple()

        collect_dir = COLLECT_FILES(all_files)
        
        manifest_dired = MANIFEST(collect_dir)
        
        manifest_checked = CHECK_INTEGRITY(manifest_dired, params.brc_mode)
        
        manifest_stated = MANIFEST_STATS(manifest_checked, 'datasets')

        // Publish the data to output directory
        PUBLISH_DIR(manifest_stated, output_dir)

}
