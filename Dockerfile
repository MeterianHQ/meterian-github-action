FROM meterian/cli:latest-gha

LABEL "repository"="http://github.com/MeterianHQ/meterian-github-action"
LABEL "homepage"="http://github.com/MeterianHQ"
LABEL "maintainer"="Bruno Bossola <bruno@meterian.io>, Mani Sarkar <sadhak001@gmail.com>"

COPY entrypoint.sh meterian.sh ./
COPY ./meterian-bot.py ./

ENTRYPOINT ["/root/entrypoint.sh"]