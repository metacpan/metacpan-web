FROM metacpan/metacpan-base:latest

ARG CPM_ARGS=--with-test

ENV NO_UPDATE_NOTIFIER=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash \
    && apt-get update \
    && apt-get install -y -f --no-install-recommends libcmark-dev nodejs \
    && apt-get clean \
    && npm install -g npm
    && rm -rf /var/lib/apt/lists/* /root/.npm

COPY . /metacpan-web/
WORKDIR /metacpan-web

RUN npm install --verbose && npm cache clean --force

RUN cpanm --notest App::cpm \
    && cpm install -g Carton \
    && useradd -m metacpan-web -g users \
    && cpm install -g ${CPM_ARGS}\
    && rm -fr /root/.cpanm /root/.perl-cpm /tmp/*

RUN chown -R metacpan-web:users /metacpan-web

USER metacpan-web:users

EXPOSE 5001

CMD ["plackup", "-p", "5001", "-r"]
