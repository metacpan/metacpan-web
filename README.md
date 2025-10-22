![test](https://github.com/metacpan/metacpan-web/workflows/test/badge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/metacpan/metacpan-web/badge.svg)](https://coveralls.io/r/metacpan/metacpan-web)

<!-- vim-markdown-toc GFM -->

- [Getting Started](#getting-started)
  - [Installing Manually](#installing-manually)
    - [Building Static Assets](#building-static-assets)
    - [Installing on macOS](#installing-on-macos)
  - [Running Tests](#running-tests)
  - [Running the App](#running-the-app)
  - [Local Git and testing considerations](#local-git-and-testing-considerations)
  - [Local Configuration Changes](#local-configuration-changes)
  - [Compatibility Notes](#compatibility-notes)

<!-- vim-markdown-toc -->

# Getting Started

We strongly recommend using
[metacpan-docker](https://github.com/metacpan/metacpan-docker). This will give
you a virtual machine already configured and ready to start developing on.

If you prefer not to use Docker, you can set up a local development environment:

## Quick Setup

For automated setup, run:

```bash
./bin/setup-dev
```

This will install all dependencies, build assets, and verify your setup.

## Installing Manually

If you prefer manual setup or need more control:

```bash
carton install
npm install
export PATH="$(realpath ./node_modules/.bin):$PATH"
```

For detailed setup instructions, see [DEVELOPMENT.md](DEVELOPMENT.md).

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

## Running the App

```bash
carton exec plackup -p 5001 -r
```

If you'd like to use `Gazelle` rather than the default Plack server:

```bash
carton exec plackup -p 5001 -s Gazelle -r
```

## Local Git and testing considerations

You will want to set up the supplied pre-commit Git hook like so:

```bash
./git/setup.sh
```

which causes `precious` to be run before each commit. You can manually run this
with `precious path/to/file`

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
