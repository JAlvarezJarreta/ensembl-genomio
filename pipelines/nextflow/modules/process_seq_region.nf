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
    label 'default'
    tag "$gca - $task.attempt"
    debug true

    input:
    path genome_json
    path assembly_report
    path gbff_file
    val gca
    // val regions_to_exclude

    output:
    path "*"

    script:
    """
    prepare_seq_region --genome_file ${genome_json} --report_file ${assembly_report} \
        --gbff_file ${gbff_file} --dst_dir ${gca}
    """
    // --to_exclude ${regions_to_exclude}
}
