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

// default params
params.help = false
params.mock = false

// Print usage
def helpMessage() {
  log.info '''
        Mandatory arguments:
        --old_registry                 Ensembl API registry for all old databases to transfer metadata from.
        --new_registry                 Ensembl API registry for all new databases to transfer metadata to.
        --species_list                 List of species (csv with one header="species") to use with both registries.

        Optional:
        --mock                         Do not transfer

        Optional arguments:
        --output_dir                   Where the logs and process files can be stored
        --help                         This usage statement
        '''
}

// Check mandatory parameters
if (params.help) {
    helpMessage()
    exit 0
}

if (!params.scripts_dir) {
    exit 1, "Missing scripts_dir"
}
if (!params.old_registry or !params.new_registry) {
    exit 1, "Missing registries parameters"
}
if (!params.species_list) {
    exit 1, "Missing species list"
}

include { TRANSFER_METADATA } from '../../modules/patch_build/transfer_metadata_publish.nf'

workflow TRANSFER {
    take:
        species_meta
        old_registry
        new_registry
    
    emit:
        logs
    
    main:
        transfer_log = TRANSFER_METADATA(species_meta, old_registry, new_registry).log

        logs = transfer_log
}

workflow {
    old_registry = Channel.fromPath(params.old_registry, checkIfExists: true).first()
    new_registry = Channel.fromPath(params.new_registry, checkIfExists: true).first()
    species_meta = Channel.fromPath(params.species_list, checkIfExists: true).splitCsv(header: true)

    logs = TRANSFER(species_meta, old_registry, new_registry)
}
