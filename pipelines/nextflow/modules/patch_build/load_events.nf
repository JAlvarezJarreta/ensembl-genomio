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

process LOAD_EVENTS {
    label 'local'

    input:
        val(server)
        path(events)

    script:
    """
    events_loader \\
    --host $server.host \\
    --user $server.user \\
    --port $server.port \\
    --password $server.password \\
    --database $server.database \\
    --input_file $events \\
    --update 1
    """
}