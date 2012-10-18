#!/bin/bash

# Workaround for a JRuby bug: http://jira.codehaus.org/browse/JRUBY-5678
export TMPDIR="`pwd`/tmp"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

# This command will run first the built-in 'prepare' task (which processes and 
# copies all template files) for all servers specified in example.rb, after which 
# it will run the 'deploy' task (which is defined in example.rb) for all of them. 
# Any Maven artifacts are copied from the local Maven repository defined here (no 
# remote repository support yet). The results will be in the output directory.
java -jar "../target/deployer-*.jar" \
    --maven-repository "../src/test/ruby/testdata/maven-repository" \
    --config-file example.rb \
    --output-dir output \
    prepare deploy
