FROM metacpan/metacpan-base:latest

ARG CPM_ARGS=--with-test

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash \
    && curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y -f --no-install-recommends libcmark-dev nodejs yarn=1.19.2-1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY . /metacpan-web/
WORKDIR /metacpan-web

RUN yarn install

RUN cpanm --notest App::cpm \
    && cpm install -g Carton \
    && useradd -m metacpan-web -g users \
    && cpm install -g ${CPM_ARGS}\
    && rm -fr /root/.cpanm /root/.perl-cpm /tmp/*

RUN chown -R metacpan-web:users /metacpan-web

USER metacpan-web:users

EXPOSE 5001

CMD ["plackup", "-p", "5001", "-r"]
