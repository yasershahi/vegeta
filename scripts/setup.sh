#!/usr/bin/env bash

set -euo pipefail

for script in /tmp/scripts/*.sh; do
  if [[ -f "$script" ]]; then
    echo "::group::===$(basename "$script")==="
    bash "$script"
    echo "::endgroup::"
  fi
done
