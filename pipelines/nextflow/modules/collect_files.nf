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

process COLLECT_FILES {
    tag "Collect_files"
    label 'default'
    time '5min'

    input:
        tuple val(accession), path(file_name)
    
    output:
        path "${accession}", emit: manifest_dir
    
    script:
        """
        DBDIR=${accession}/
        mkdir \$DBDIR
        echo ${file_name}
        for FILE in ${file_name}; do
            if [ -s \$FILE ]; then
                mv \$FILE \$DBDIR
            fi
        done
        """
}

process MANIFEST {
    tag "Manifest_$accession"
    label 'default'
    
    input:
        path manifest_dir
        val accession

    output:
        path manifest_dir
    
    script:
        """
        manifest_maker --manifest_dir ${manifest_dir}
        """
}

process PUBLISH_DIR {
    publishDir "$out_dir", mode: 'copy', overwrite: false
    tag "Publish_${accession}"
    label 'default'
    time '5min'

    input:
        path data_dir
        val out_dir
        val accession
    
    output:
        path data_dir
    
    script:
        """
        echo "Just copy over the finished files"
        echo "From '$data_dir' to '$out_dir' for accession '$accession'"
        """
}