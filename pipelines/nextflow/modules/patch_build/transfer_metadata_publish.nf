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

process TRANSFER_METADATA {
    tag "$meta.species"
    label 'adaptive'
    publishDir "$params.output_dir/$meta.species", mode: 'copy'
    maxForks 10

    input:
        val(meta)
        path(old_registry)
        path(new_registry)
    
    output:
        tuple val(meta), path("transfer_metadata.err"), emit: error
        tuple val(meta), path("transfer_metadata.log"), emit: log

    script:
        update = params.mock ? "" : "--update"
        """
        perl $params.scripts_dir/transfer_metadata.pl \\
            --old ./$old_registry \\
            --new ./$new_registry \\
            --species $meta.species \\
            --descriptions \\
            --versions \\
            --xrefs \\
            --transfer_log transfer_metadata.log \\
            --verbose \\
            $update 2> transfer_metadata.err
        """
}