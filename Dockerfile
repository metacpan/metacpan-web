ARG SLIM_BUILD
ARG MAYBE_BASE_BUILD=${SLIM_BUILD:+server-base-slim}
ARG BASE_BUILD=${MAYBE_BASE_BUILD:-server-base}

################### Asset Builder

FROM node:25-alpine AS build-assets
ENV NO_UPDATE_NOTIFIER=1
SHELL [ "/bin/sh", "-euo", "pipefail", "-c" ]

WORKDIR /build/

COPY package.json package-lock.json ./
RUN \
    --mount=type=cache,target=/root/.npm,sharing=private \
<<EOT
    npm install --verbose
EOT

# not supported yet
#COPY --parents build-assets.mjs root/static ./

COPY build-assets.mjs ./
COPY root/static root/static
RUN <<EOT
    npm run build:min
EOT

HEALTHCHECK CMD [ "test", "-e", "root/assets/assets.json" ]

################### Web Server Base
FROM metacpan/metacpan-base:main-20250531-090128 AS server-base
FROM metacpan/metacpan-base:main-20250531-090129-slim AS server-base-slim

################### CPAN Prereqs
FROM server-base AS build-cpan-prereqs
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

ARG COMRAK_FFI_VERSION=v0.0.1
ADD https://github.com/oalders/comrak-ffi/releases/download/${COMRAK_FFI_VERSION}/libcomrak_ffi.so.x86_64-unknown-linux-gnu /usr/local/lib/libcomrak_ffi.so
RUN chmod 644 /usr/local/lib/libcomrak_ffi.so && ldconfig

WORKDIR /app/

COPY cpanfile cpanfile.snapshot ./
RUN \
    --mount=type=cache,target=/root/.perl-cpm,sharing=private \
<<EOT
    cpm install --show-build-log-on-failure --resolver=snapshot
EOT

################### CPAN Dev Prereqs
FROM build-cpan-prereqs AS build-cpan-dev-prereqs
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

RUN \
    --mount=type=cache,target=/root/.perl-cpm,sharing=private \
<<EOT
    cpm install --show-build-log-on-failure --resolver=snapshot --with-develop
EOT

################### Web Server
# false positive
# hadolint ignore=DL3006
FROM ${BASE_BUILD} AS server
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

COPY --from=build-cpan-prereqs /usr/local/lib/libcomrak_ffi.so /usr/local/lib/libcomrak_ffi.so
RUN ldconfig

WORKDIR /app/

COPY *.md app.psgi log4perl* metacpan_web.* metacpan_web_local.* ./
COPY bin bin
COPY lib lib
COPY root root

COPY --from=build-assets /build/root/assets root/assets
COPY --from=build-cpan-prereqs /app/local local

ENV PERL5LIB="/app/local/lib/perl5"
ENV PATH="/app/local/bin:${PATH}"
ENV METACPAN_WEB_HOME=/app

CMD [ \
    "/uwsgi.sh", \
    "--http-socket", ":8000" \
]

EXPOSE 8000

HEALTHCHECK --start-period=3s CMD [ "curl", "--fail", "http://localhost:8000/healthcheck" ]

################### Development Server
FROM server AS develop
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

ENV COLUMNS=120
ENV PLACK_ENV=development

USER root

COPY --from=build-cpan-dev-prereqs /app/local local
RUN chown -R metacpan:users ./

USER metacpan

################### Test Runner
FROM develop AS test
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

ENV NO_UPDATE_NOTIFIER=1
ENV PLACK_ENV=

USER root

RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=private \
    --mount=type=cache,target=/root/.npm,sharing=private \
<<EOT
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt-get update
    apt-get satisfy -y -f --no-install-recommends 'nodejs (>= 24.1.0)'
    npm install -g npm@^11.4.1
EOT

COPY package.json package-lock.json ./
RUN \
    --mount=type=cache,target=/root/.npm,sharing=private \
<<EOT
    npm install --verbose --include=dev
EOT

COPY cpanfile cpanfile.snapshot ./
RUN \
    --mount=type=cache,target=/root/.perl-cpm \
<<EOT
    cpm install --show-build-log-on-failure --resolver=snapshot --with-test
EOT

COPY t t

RUN git config --system --add safe.directory /app

USER metacpan
CMD [ "prove", "-l", "-r", "-j", "2", "t" ]

################### Linting
FROM test AS lint
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

USER root

COPY bin/install-precious ./bin/
RUN --mount=type=secret,id=github_token \
    GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null)" \
    ./bin/install-precious /usr/local/bin

COPY .perlcriticrc .perltidyrc perlimports.toml precious.toml eslint.config.mjs .editorconfig ./

USER metacpan

################### Playwright Test Runner
FROM test AS playwright-test
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]

USER root
RUN npx playwright install-deps chromium

USER metacpan
RUN npx playwright install chromium

CMD ["npx", "playwright", "test"]

################### Playwright Server
FROM server AS playwright
USER root

RUN    --mount=type=cache,target=/root/.perl-cpm,sharing=private \
<<EOT
    cpm install --show-build-log-on-failure Devel::Cover
EOT

RUN mkdir -p /app/cover_db && chown metacpan:users /app/cover_db

USER metacpan

ENV PERL5OPT=-MDevel::Cover=-db,/app/cover_db,-ignore,^local/,^templates/,^t/,yaml$

CMD ["/app/bin/plackup-cover", "-p", "8000", "app.psgi"]

################### Production Server
FROM server AS production

RUN perl -Ilib -MMetaCPAN::Web -e'MetaCPAN::Web->new->compile'

USER metacpan
