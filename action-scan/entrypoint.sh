#!/bin/sh -l

METERIAN_ARGS="$*"
sh -c "java -jar /.meterian/meterian-cli.jar ${METERIAN_ARGS}"