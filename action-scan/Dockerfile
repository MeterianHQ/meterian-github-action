FROM maven:3-alpine

LABEL "com.github.actions.name"="Meterian Scanner"
LABEL "com.github.actions.description"="Scan a Java repository for vulnerabilities"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="http://github.com/neomatrix369/meterian-scanner-action"
LABEL "homepage"="http://github.com/neomatrix369"
LABEL "maintainer"="Mani Sarkar <sadhak001@gmail.com>"

RUN mkdir /.meterian

RUN curl -o /.meterian/meterian-cli.jar  -O -J \
         -L https://www.meterian.com/latest-client-canary

ARG METERIAN_CLIENT_JAR
COPY ${METERIAN_CLIENT_JAR} /${METERIAN_CLIENT_JAR}

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]