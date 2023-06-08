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

process PROCESS_SEQ_REGION {
    label 'adaptive'
    tag "$gca - $task.attempt"
    debug true

    input:
        tuple val(gca), path (genome_json)
        tuple val(gca), path (assembly_report), path (genomic_fna), path (genomic_gbff)

    output:
        tuple val(gca), path("*/seq_region.json"), emit: seq_region

    script:
    """
    prepare_seq_region --genome_file ${genome_json} --report_file ${assembly_report} \
        --gbff_file ${genomic_gbff} --dst_dir ${gca}
    """
    // --to_exclude ${regions_to_exclude}
}
