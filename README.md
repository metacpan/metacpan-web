[![Build Status](https://travis-ci.org/CPAN-API/metacpan-web.png?branch=master)](https://travis-ci.org/CPAN-API/metacpan-web)
[![Coverage Status](https://coveralls.io/repos/CPAN-API/metacpan-web/badge.png)](https://coveralls.io/r/CPAN-API/metacpan-web)

## GETTING STARTED

We strongly recommend using [metacpan-developer](https://github.com/CPAN-API/metacpan-developer),
this will give you a virtual machine already configured and ready to start developing on.

## Installing manually

Install the project dependencies:

    $ cpanm --installdeps .

Run test suite:

    $ prove -lr t/

Start server on port 5001 (which you want to make authentication work)

    $ plackup -p 5001 -r

## Installing manually via carton

If you prefer to use carton to manage your dependencies, then the above
commands can be converted to:

    $ carton install
    $ carton exec prove -lr t/
    $ carton exec plackup -p 5001 -r

## Local configuration changes

The backend defaults to C<api.metacpan.org>. Running a local API server is
optional and not required to hack on the front-end.  The address to the API
user can be changed in the metacpan_web.conf file.  Ideally you would create a
new file called C<metacpan_web_local.conf> that contains

    api        http://127.0.0.1:5000
    api_secure http://127.0.0.1:5000

which will be loaded on top of the existing config file.


## COMPATIBILITY NOTES

On Win32 (and possibly also on other platforms) when using Perl < 5.12, the
server started with plackup will generate warnings relating to date parsing.
These are caused by Plack due to a bug in the gmtime implementation and can be
removed by upgrading to Perl 5.12.
