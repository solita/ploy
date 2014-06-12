#!/bin/bash
set -eu
: ${1:? Usage: $0 DESCRIPTION}
DESCRIPTION="$1"
set -x

mvn clean verify \
    --errors
