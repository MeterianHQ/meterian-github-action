FROM maven:3-alpine

LABEL "com.github.actions.name"="Meterian Scanner"
LABEL "com.github.actions.description"="Scan a Java repository for vulnerabilities"
LABEL "com.github.actions.icon"="zoom-in"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="http://github.com/MeterianHQ/meterian-github-action"
LABEL "homepage"="http://github.com/MeterianHQ"
LABEL "maintainer"="Bruno Bossola <bruno@meterian.io>, Mani Sarkar <sadhak001@gmail.com>"

RUN mkdir /.meterian

RUN curl -o /.meterian/meterian-cli.jar \
         -O -J -L https://www.meterian.com/latest-client-canary

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]