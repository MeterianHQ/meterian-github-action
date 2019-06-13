#!/bin/sh -l

sh -c "java -version"
sh -c "java -jar $HOME/.meterian/meterian-cli.jar --autofix"