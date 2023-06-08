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

process UNPACK_GFF3 {
    label 'default'

    input:
        tuple val(gca), path(compressed_gff), path(protein_faa), path(gbff)
        val extension

    output:
        tuple val(gca), path("*.${extension}")
    
    script:
    """
    extract_file --src_file ${compressed_gff} --dst_dir "."
    """
}
