#!/bin/bash

# Workaround for a JRuby bug: http://jira.codehaus.org/browse/JRUBY-5678
export TMPDIR="`pwd`/tmp"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

# This command will run first the 'prepare' task for all servers
# specified in example.rb, after which it will run the 'deploy' task
# for all of them. The results will be in the output directory.
java -jar "../target/deployer-*.jar" \
    --maven-repository "../src/test/ruby/testdata/maven-repository" \
    --config-file example.rb \
    --output-dir output \
    prepare deploy
