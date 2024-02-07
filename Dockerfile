FROM metacpan/metacpan-base:latest

ARG CPM_ARGS=--with-test

ENV NO_UPDATE_NOTIFIER=1

RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=private \
    --mount=type=cache,target=/root/.npm,sharing=private \
<<EOT /bin/bash -euo pipefail
    curl -fsSL https://deb.nodesource.com/setup_21.x | bash -
    apt-get update
    apt-get install -y -f --no-install-recommends nodejs
    npm install -g npm
    apt-get install -y -f libcmark-dev
    apt-get clean autoclean
    apt-get autoremove --yes
EOT

WORKDIR /metacpan-web/

COPY --chown=metacpan:users package.json package-lock.json .
RUN \
    --mount=type=cache,target=/root/.npm,sharing=private \
<<EOT /bin/bash -euo pipefail
    npm install --verbose
    npm audit fix
EOT

COPY --chown=metacpan:users cpanfile cpanfile.snapshot .
RUN \
    --mount=type=cache,target=/root/.perl-cpm,sharing=private \
<<EOT /bin/bash -euo pipefail
    cpm install -g ${CPM_ARGS}
EOT

COPY --chown=metacpan:users . .
RUN mkdir var && chown metacpan:users var

USER metacpan

EXPOSE 5001

CMD ["plackup", "-p", "5001", "-r"]
