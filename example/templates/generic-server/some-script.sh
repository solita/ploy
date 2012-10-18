#!/bin/sh

# We can use Ruby ERB for filling in replacement variables
echo "Another variable was <%= another_variable %>"

# We can also use replacement variables like this to create an install script
cp "webapps-dir/sample.war" "<%= tomcat_home %>/webapps-dir/"
