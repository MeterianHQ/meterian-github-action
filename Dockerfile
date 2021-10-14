FROM meterian/cli:latest

LABEL "repository"="http://github.com/MeterianHQ/meterian-github-action"
LABEL "homepage"="http://github.com/MeterianHQ"
LABEL "maintainer"="Bruno Bossola <bruno@meterian.io>, Mani Sarkar <sadhak001@gmail.com>"

RUN pip3 install --ignore-installed PyGithub

COPY ./*.sh ./
COPY ./submit_pr.py ./

ENTRYPOINT ["/root/entrypoint.sh"]