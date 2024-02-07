FROM metacpan/metacpan-base:latest

ARG CPM_ARGS=--with-test

ENV NO_UPDATE_NOTIFIER=1

RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=private \
    --mount=type=cache,target=/root/.npm,sharing=private \
<<EOT /bin/bash -euo pipefail
    curl -fsSL https://deb.nodesource.com/setup_21.x | bash -
    apt update
    apt install -y -f --no-install-recommends nodejs
    npm install -g npm
    apt install -y -f libcmark-dev
EOT

WORKDIR /metacpan-web/
RUN chown metacpan:users /metacpan-web/

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

CMD [ \
    "/usr/bin/uwsgi", \
    "--plugins", "psgi", \
    "--uwsgi-socket", ":3031", \
    "--http-socket", ":80", \
    "--http-socket-modifier1", "5", \
    "--ini", "/metacpan-web/servers/uwsgi.ini", \
    "--psgi", "app.psgi" \
]

EXPOSE 80 3031
