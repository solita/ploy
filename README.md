
Deployer
========

Command line tool for automating software deployments on multiple machines. Uses
templates and replacement variables to generate machine specific configuration
files, and provides a way to execute arbitrary Ruby code for deploying the
artifacts on a server.

For usage instructions, see the comments in the files in the `example` directory.
Run the example using the commands:

    mvn clean verify
    cd example
    ./run.sh

Requires Maven 3 and Java 6 or higher. Includes JRuby in Ruby 1.9 mode.

Licensed under the MIT license.
