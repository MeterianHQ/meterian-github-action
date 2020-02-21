FROM openjdk:8-jdk

LABEL "repository"="http://github.com/MeterianHQ/meterian-github-action"
LABEL "homepage"="http://github.com/MeterianHQ"
LABEL "maintainer"="Bruno Bossola <bruno@meterian.io>, Mani Sarkar <sadhak001@gmail.com>"

### Variables
ARG DOTNET_VERSION=3.1
ARG MAVEN_VERSION=3.6.3
ARG PHP_VERSION=7.2
ARG NODE_VERSION=13.x
ARG GRADLE_VERSION=6.1

### GitHub action version
ARG VERSION=0.2.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


### General setup
RUN  apt-get update \
  && apt-get -y install apt-transport-https apt-utils


### Dotnet sdk install
RUN  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg \
  && mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ \
  && wget -q https://packages.microsoft.com/config/debian/9/prod.list \
  && mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
  && chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg \
  && chown root:root /etc/apt/sources.list.d/microsoft-prod.list \
  && apt-get update \
  && apt-get -y install dotnet-sdk-${DOTNET_VERSION} \
  && wget -q https://packages.microsoft.com/config/ubuntu/19.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb \
  && dpkg -i /tmp/packages-microsoft-prod.deb \
  && rm /tmp/packages-microsoft-prod.deb


### Maven install
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn


## PHP install
RUN apt install -qy apt-transport-https lsb-release ca-certificates \
  && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
  && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
  && apt update \
  && apt -qy install php${PHP_VERSION} \
  && php -v \
  && apt update \
  && apt -qy install php${PHP_VERSION}-mbstring \
  && curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php \
  && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && rm /tmp/composer-setup.php \
  && composer --version


## Ruby install
RUN apt-get update \ 
  && apt-get install -qy ruby \
  && ruby -v \
  && gem install bundler \
  && bundle -v

  
## Python install
RUN apt-get install -qy python-pip \
  && pip -V \
  && pip install pipenv \
  && pipenv --version


### Node install
RUN apt-get install -qy software-properties-common \
  && curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -\
  && apt-get install -qy nodejs \
  && node -v


## Gradle install
RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \
  && unzip -d /opt/gradle /tmp/gradle-*.zip \
  && echo "export GRADLE_HOME=/opt/gradle/gradle-\${GRADLE_VERSION}" >> /tmp/gradle.sh \
  && echo "export PATH=\${GRADLE_HOME}/bin:\${PATH}" >> /tmp/gradle.sh \
  && source /tmp/gradle.sh \
  && gradle -v \
  && rm /tmp/gradle* 


## Scala install
RUN apt-get install -qy scala \
  && scala -version \
  && echo "deb https://dl.bintray.com/sbt/debian /" >> /etc/apt/sources.list.d/sbt.list \
  && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add \
  && apt-get update \
  && apt-get install -qy sbt


### Setup initial meterian client (it will be updated if required)
RUN curl -o /meterian-cli.jar -O -J -L https://www.meterian.com/downloads/meterian-cli.jar


### Setup GitHub action version stamp
RUN test -n "${VERSION}"
RUN  echo "© 2017-2020 Meterian Ltd - GitHub action version ${VERSION}" > /root/version.txt


### Final entrypoint setup
WORKDIR /root
COPY entrypoint.sh meterian.sh ./
ENTRYPOINT ["/root/entrypoint.sh"]


### Removing vulnerable components, also they are not used for the purpose of this image
RUN apt-get remove -qy mercurial python2.7 wget

