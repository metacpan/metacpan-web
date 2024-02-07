FROM metacpan/metacpan-base:latest

ARG CPM_ARGS=--with-test

ENV NO_UPDATE_NOTIFIER=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash \
    && apt-get update \
    && apt-get install -y -f --no-install-recommends libcmark-dev dumb-init nodejs \
    && apt-get clean \
    && npm install -g npm \
    && rm -rf /var/lib/apt/lists/* /root/.npm

WORKDIR /metacpan-web

COPY package.json package-lock.json .
RUN npm install --verbose && npm cache clean --force

COPY --chown=metacpan:users cpanfile cpanfile.snapshot .
RUN cpanm --notest App::cpm \
    && cpm install -g Carton \
    && useradd -m metacpan-web -g users \
    && cpm install -g ${CPM_ARGS}\
    && rm -fr /root/.cpanm /root/.perl-cpm /tmp/*

COPY . /metacpan-web/
RUN chown -R metacpan-web:users /metacpan-web

USER metacpan-web:users

EXPOSE 5001

# Runs "/usr/bin/dumb-init -- /my/script --with --args"
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["plackup", "-p", "5001", "-r"]
