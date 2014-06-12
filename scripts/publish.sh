#!/bin/bash
set -eu
: ${1:? Usage: $0 DESCRIPTION}
DESCRIPTION="$1"
set -x

# TODO: upload to download site and push to GitHub automatically

set +x
echo ""
echo "Done. Next steps:"
echo "    upload target/*.jar to download site"
echo "    git push origin HEAD"
echo "    git push origin --tags"
