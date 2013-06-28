## GETTING STARTED

Install the project dependencies:

 $ cpanm --installdeps .

Start server on port 5001 (which you want to make authentication work)

 $ plackup -p 5001 -r

The backend defaults to C<api.metacpan.org>. Running a local API server is optional and not required to hack on the front-end.
The address to the API user can be changed in the metacpan_web.conf file.
Ideally you would create a new file called C<metacpan_web_local.conf> that contains

 api        http://127.0.0.1:5000
 api_secure http://127.0.0.1:5000

which will be loaded on top of the existing config file.


## COMPATIBILITY NOTES

On Win32 (and possibly also on other platforms) when using Perl < 5.12, the server started with plackup will generate warnings relating to date parsing. These are caused by Plack due to a bug in the gmtime implementation and can be removed by upgrading to Perl 5.12.
