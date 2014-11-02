[![Build Status](https://travis-ci.org/CPAN-API/metacpan-web.png?branch=master)](https://travis-ci.org/CPAN-API/metacpan-web)
[![Coverage Status](https://coveralls.io/repos/CPAN-API/metacpan-web/badge.png)](https://coveralls.io/r/CPAN-API/metacpan-web)

## GETTING STARTED

We strongly recommend using [metacpan-developer](https://github.com/CPAN-API/metacpan-developer),
this will give you a virtual machine already configured and ready to start developing on.

    $ vagrant ssh
    $ cd $HOME/metacpan-web
    $ sudo service starman_metacpan-web restart

You'll find some log files in var/logs.

## Installing manually

If you prefer not to use the VM, the following commands will get you started:
commands can be converted to:

    $ carton install
    $ ./bin/prove t
    $ carton exec plackup -p 5001 -r

## Local configuration changes

The backend defaults to `api.metacpan.org`. Running a local API server is
optional and not required to hack on the front-end.  The address to the API
user can be changed in the `metacpan_web.conf` file.  Ideally you would create a
new file called `metacpan_web_local.conf` that contains

    api                 http://127.0.0.1:5000
    api_external        http://127.0.0.1:5000
    api_secure          http://127.0.0.1:5000
    api_external_secure http://127.0.0.1:5000

which will be loaded on top of the existing config file.


## COMPATIBILITY NOTES

On Win32 (and possibly also on other platforms) when using Perl < 5.12, the
server started with plackup will generate warnings relating to date parsing.
These are caused by Plack due to a bug in the gmtime implementation and can be
removed by upgrading to Perl 5.12.

## Running in [docker](https://www.docker.com/)

This feature is highly experimental and is not officially supported. It works,
but it should be heavily tested.

You can build a docker image with command:

    docker build --tag metacpan .

And when you have docker image you can run in with the command:

    docker run --publish 8000:5001 --detach metacpan

With running container you can open metacpan web at http://127.0.0.1:8000
(but you need to change 127.0.0.1 to the ip of your docker virtual machine)

If you want to run metacpan web with your custom config you can use config
file from your docker host system like this:

    docker run \
        --publish 8000:5001 \
        --volume /absolute/path/to/metacpan_web.conf:/root/metacpan_web.conf \
        --detach \
        metacpan
