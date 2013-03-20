
Ploy: Deployment Automation Tool
================================

Command line tool for automating software deployments on multiple machines. Uses
templates and replacement variables to generate machine specific configuration
files, and provides a way to execute arbitrary Ruby code for deploying the
artifacts on a server.

For usage instructions, see the comments in the files in the `example` directory.
Run the example using the commands:

    mvn clean verify
    cd example
    ./run.sh

Requires Maven 3 and Java 7 or higher. Includes JRuby in Ruby 1.9 mode.

Licensed under the MIT license.


Release Notes
-------------

**Next Release**

- Renamed the project to Ploy ([#9](https://github.com/solita/ploy/issues/9))
- Retains the permission bits of files generated based on templates ([#2](https://github.com/solita/ploy/issues/2))
- Better compatibility: doesn't anymore use the `jar` command for handling ZIP files, but uses Java's standard library
- Upgraded to Java 7
- Upgraded to JRuby 1.7 ([#5](https://github.com/solita/ploy/issues/5))

**v1.0.0** (2012-10-18)

- Initial release
