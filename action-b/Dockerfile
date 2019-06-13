FROM bridg/java8

ARG METERIAN_API_TOKEN
ENV METERIAN_API_TOKEN

LABEL "com.github.actions.name"="Hello World"
LABEL "com.github.actions.description"="Write arguments to the standard output"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="http://github.com/neomatrix369/hello-world-github-actions"
LABEL "homepage"="http://github.com/actions"
LABEL "maintainer"="Mani Sarkar <sadhak001@gmail.com>"

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]