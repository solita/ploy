
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

**v1.2.0** (2013-08-13)

- Can locate Maven 3's unique timestamped snapshots

**v1.1.0** (2013-03-20)

- Created `with_webapp` that takes the path to the webapps directory as parameter. This replaces the old way of using `with_artifact` and specifying the webapps directory in `.template.rb` ([#7](https://github.com/solita/ploy/issues/7))
- Can generate arbitrary files using `with_file` ([#8](https://github.com/solita/ploy/issues/8))
- Retains the permission bits of files generated based on templates ([#2](https://github.com/solita/ploy/issues/2))
- Better compatibility: doesn't anymore use the `jar` command for handling ZIP files, but uses Java's standard library
- Renamed the project to Ploy ([#9](https://github.com/solita/ploy/issues/9))
- Upgraded to Java 7
- Upgraded to JRuby 1.7 ([#5](https://github.com/solita/ploy/issues/5))

**v1.0.0** (2012-10-18)

- Initial release
