![test](https://github.com/metacpan/metacpan-web/workflows/test/badge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/metacpan/metacpan-web/badge.svg)](https://coveralls.io/r/metacpan/metacpan-web)

<!-- vim-markdown-toc GFM -->

- [Getting Started](#getting-started)
  - [Installing Manually](#installing-manually)
    - [Building Static Assets](#building-static-assets)
    - [Installing on macOS](#installing-on-macos)
  - [Running Tests](#running-tests)
    - [Running Tests with Docker Compose](#running-tests-with-docker-compose)
    - [Running Playwright (E2E) Tests](#running-playwright-e2e-tests)
      - [Running with Docker Compose](#running-with-docker-compose)
      - [Running Locally](#running-locally)
  - [Running the App](#running-the-app)
    - [Running with Docker Compose](#running-with-docker-compose-1)
    - [Running Locally](#running-locally-1)
  - [Linting and Tidying with Precious](#linting-and-tidying-with-precious)
    - [Running via Docker](#running-via-docker)
    - [Running Locally](#running-locally-2)
    - [Pre-commit Hook](#pre-commit-hook)
  - [Local Configuration Changes](#local-configuration-changes)
  - [Compatibility Notes](#compatibility-notes)

<!-- vim-markdown-toc -->

# Getting Started

We strongly recommend using
[metacpan-docker](https://github.com/metacpan/metacpan-docker). This will give
you a virtual machine already configured and ready to start developing on.

If you prefer not to use Docker, the following commands will get you started:

## Installing Manually

```bash
carton install
npm install
export PATH="$(realpath ./node_modules/.bin):$PATH"
```

### Building Static Assets

```bash
npm run build
```

Without running this command you may get errors about a missing "asset map".

### Installing on macOS

If you like, you can install `carton` and `cmark` via Homebrew:

```bash
brew install carton cmark
```

On an ARM Mac you may need to install
[CommonMark](https://metacpan.org/pod/CommonMark) in the following way:

```bash
LIBRARY_PATH=/opt/homebrew/lib CPATH=/opt/homebrew/include cpm install -g CommonMark
```

If your `carton install` is having issues with SSL-related modules, you may need
to use an `OPENSSL_PREFIX`. Something like:

```bash
OPENSSL_PREFIX="/usr/local/Cellar/openssl@1.1/1.1.1q" carton install
```

You may need to check `/usr/local/Cellar/openssl@1.1` to find the latest
installed path on your system.

## Running Tests

You can use the supplied wrapper around `prove` to run tests:

```bash
./bin/prove t
```

To run the tests in parallel, add `-j8` (or however many CPUs you have) to the
`prove` command.

### Running Tests with Docker Compose

Run all tests using the `test` profile:

```bash
docker compose --profile test run --rm test
```

Run an arbitrary command:

```bash
docker compose --profile test run --rm test prove -lvr t/controller/search.t
```

### Running Playwright (E2E) Tests

Playwright tests live in the `e2e/` directory.

#### Running with Docker Compose

```bash
docker compose --profile test run --rm playwright
```

#### Running Locally

```bash
npm test
```

This automatically starts a local server on port 5099 (via `plackup`) before
running the tests. If a server is already running on that port, it will be
reused.

To run the tests against a server you've already started on a different port:

```bash
PLAYWRIGHT_PORT=5001 npm test
```

When `PLAYWRIGHT_PORT` is set, Playwright skips starting its own server and
connects to the specified port instead.

## Running the App

### Running with Docker Compose

```bash
docker compose up --watch
```

Start the asset builder and the web server. The site will be served on
port 5001. The `--watch` flag enables automatic rebuilds when files change.

### Running Locally

```bash
carton exec plackup -p 5001 -r
```

If you'd like to use `Gazelle` rather than the default Plack server:

```bash
carton exec plackup -p 5001 -s Gazelle -r
```

## Linting and Tidying with Precious

This project uses [precious](https://github.com/houseabsolute/precious) to run
linters and tidiers (perltidy, perlcritic, perlimports, eslint, prettier,
omegasort).

### Running via Docker

The test Docker image includes all linting tools. No local installation needed:

```bash
docker compose --profile test run --rm test precious lint --git
docker compose --profile test run --rm test precious tidy --git
```

### Running Locally

If you prefer to run precious locally, install it with:

```bash
./bin/install-precious /usr/local/bin
```

### Pre-commit Hook

You will want to set up the supplied pre-commit Git hook like so:

```bash
./git/setup.sh
```

which causes `precious` to be run before each commit.

## Local Configuration Changes

The back end defaults to `api.metacpan.org/v1`. Running a local API server is
optional and not required to hack on the front end. The address to the API being
used can be changed in the `metacpan_web.yaml` file. Ideally you would create a
new file called `metacpan_web_local.yaml` that contains

```bash
api: http://127.0.0.1:5000
```

which will be loaded on top of the existing config file.

## Compatibility Notes

On Win32 (and possibly also on other platforms) when using Perl < 5.12, the
server started with plackup will generate warnings relating to date parsing.
These are caused by Plack due to a bug in the gmtime implementation and can be
removed by upgrading to Perl 5.12.
