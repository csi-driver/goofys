#!/bin/bash

# Copyright 2019 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eo pipefail

readonly endpoint="unix:///tmp/csi.sock"
nodeid="CSINode"
if [[ "$#" -gt 0 ]] && [[ -n "$1" ]]; then
  nodeid="$1"
fi

_output/goofysplugin --endpoint "$endpoint" --nodeid "$nodeid" -v=5 &

echo "Begin to run sanity test..."
csi-sanity --ginkgo.v --csi.endpoint=$endpoint -ginkgo.skip="should fail when requesting to create a volume with already existing name and different capacity"
