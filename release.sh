#!/bin/bash
set -eu

echo "Release version number: "
read RELEASE_VERSION

echo "Next development version (without \"-SNAPSHOT\"): "
read NEXT_VERSION
NEXT_VERSION="$NEXT_VERSION-SNAPSHOT"

set -x

git reset

mvn versions:set --batch-mode --errors -DgenerateBackupPoms=false -DnewVersion="$RELEASE_VERSION"
git add pom.xml
git commit -m "Release $RELEASE_VERSION"
git tag -s -m "Release $RELEASE_VERSION" "v$RELEASE_VERSION"

mvn clean verify

mvn versions:set --batch-mode --errors -DgenerateBackupPoms=false -DnewVersion="$NEXT_VERSION"
git add pom.xml
git commit -m "Prepare for next development iteration"
