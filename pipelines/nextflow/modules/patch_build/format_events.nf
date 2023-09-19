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

process FORMAT_EVENTS {
    label 'local'

    input:
        path(events, stageAs: "annotation_events.txt")
        path(deletes)
        path(new_genes)
        val(release)
    
    output:
        path("events.tab")

    script:
    def final_events = "events.tab"
    """
    format_events \\
    --input_file $events \\
    --map $new_genes \\
    --deletes $deletes \\
    --release_name $release.name \\
    --release_date $release.date \\
    --output_file $final_events
    """
}