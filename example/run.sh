#!/bin/bash

# Workaround for a JRuby bug: http://jira.codehaus.org/browse/JRUBY-5678
export TMPDIR="`pwd`/tmp"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

java -jar "../target/deployer-*.jar" \
    --maven-repository "../src/test/ruby/testdata/maven-repository" \
    --config-file example.rb \
    --output-dir output \
    prepare deploy
