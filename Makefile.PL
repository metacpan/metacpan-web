use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
  ABSTRACT => "A web front-end to the cpan api",
  AUTHOR => 'Moritz Onken <onken@netcubed.de>, Olaf Alders <olaf@wundercounter.com>',

  # modules required for testing
  BUILD_REQUIRES => {
    "App::Prove" => 0,
    "Test::MockObject" => "1.09",
    "Test::More" => "0.96",
    "Test::XPath" => "0.15",
    "overload" => 0,
    "utf8" => 0,
  },

  CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => "6.30"
  },

  DISTNAME => "MetaCPAN-Web",
  LICENSE => "perl",
  NAME => "MetaCPAN::Web",

  # runtime dependencies
  PREREQ_PM => {
    "AnyEvent::Curl::Multi" => 0,
    "CPAN::Meta::Requirements" => 0,
    "Captcha::reCAPTCHA" => "0.94",
    "Catalyst" => "5.90011",
    "Catalyst::Action::RenderView" => 0,
    "Catalyst::Authentication::Store::Proxy" => "0.0.1",
    "Catalyst::Authentication::User" => 0,
    "Catalyst::Controller::ActionRole" => 0,
    "Catalyst::Model" => 0,
    "Catalyst::Plugin::Authentication" => 0,
    "Catalyst::Plugin::ConfigLoader" => 0,
    "Catalyst::Plugin::Static::Simple" => 0,
    "Catalyst::Plugin::Unicode::Encoding" => 0,
    "Catalyst::Runtime" => "5.90042",
    "Catalyst::TraitFor::Request::REST::ForBrowsers" => 0,
    "Catalyst::View::JSON" => 0,
    "Catalyst::View::TT::Alloy" => 0,
    "CatalystX::RoleApplicator" => 0,
    "Config::General" => 0,
    "CPAN::Changes" => 0.21,
    "Data::Dumper" => 0,
    "DateTime" => 0,
    "DateTime::Format::HTTP" => 0,
    "DateTime::Format::ISO8601" => 0,
    "Digest::MD5" => 0,
    "Digest::SHA1" => 0,
    "Encode" => "2.10",
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => "6.30",
    "File::Find::Rule::Perl" => 0,
    "File::Path" => 0,
    "Gravatar::URL" => 0,
    "HTML::Restrict" => 0,
    "HTML::Tree" => 0,
    "HTTP::Message::PSGI" => 0,
    "HTTP::Request" => 0,
    "HTTP::Request::Common" => 0,
    "Hash::AsObject" => 0,
    "Hash::Merge" => 0,
    "JSON" => 0,
    "JSON::XS" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::ClassAttribute" => 0,
    "Perl::PrereqScanner" => "1.014",
    "Plack::Middleware::Assets" => 0,
    "Plack::Middleware::ReverseProxy" => 0,
    "Plack::Middleware::Runtime" => 0,
    "Plack::Middleware::ServerStatus::Lite" => 0,
    "Plack::Middleware::Session" => 0,
    "Plack::Middleware::Session::Cookie" => 0,
    "Plack::Response" => 0,
    "Plack::Session" => 0,
    "Plack::Test" => 0,
    "Regexp::Common" => 0,
    "Regexp::Common::time" => 0,
    "Template::Alloy" => 0,
    "Template::Plugin::DateTime" => 0,
    "Template::Plugin::JSON" => 0,
    "Template::Plugin::Markdown" => 0,
    "Template::Plugin::Number::Format" => 0,
    "Template::Plugin::Page" => 0,
    "Try::Tiny" => "0.09",
    "URI" => 0,
    "XML::Feed" => 0,
    "base" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "version" => '0.77',
    "warnings" => 0,
  },

  # We don't need 'make' or 'make install' but cpanm won't find deps
  # from WriteEmptyMakefile.  To avoid unnecessary bulding (pm_to_blib, etc)
  # we supply our own 'test' in the postamble.
  SKIP => [qw( all test install )],

  VERSION => "0.0.1",
);


# backward compatibility with older EUMM's
unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

# stuff to append to the Makefile
sub MY::postamble {
  return <<POST

# let install exist but make it a no-op
# that way 'cpanm .' appears successful
install:

test :
\t prove -lr t/

POST
}

1;
