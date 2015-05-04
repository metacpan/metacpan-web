# How to contribute

We are always after more contributors and suggestions.

## Suggestions or issues with metacpan...

#### Does it relate to our API (backend)... ?

 1. Please check the [previously reported API issues](https://github.com/CPAN-API/cpan-api/issues)
 2. Please check the [Wishlist](https://github.com/CPAN-API/cpan-api/wiki/Wishlist).  If you can't find it already there:
    * If it's a wishlist idea, please edit the [wiki](https://github.com/CPAN-API/cpan-api/wiki/Wishlist) (add a 'wishlist_MYIDEA' page if you need more space!)
    * If it's an actual bug [create a new issue](https://github.com/CPAN-API/cpan-api/issues/new)

#### If you are not sure, or it is related to https://metacpan.org/ front end:

 1. Please check the [previously reported Web issues](https://github.com/CPAN-API/metacpan-web/issues)
 2. Please check the [Wishlist](https://github.com/CPAN-API/cpan-api/wiki/Wishlist). If you can't find it already there:
    * If it's a wishlist idea, please edit the [wiki](https://github.com/CPAN-API/cpan-api/wiki/Wishlist) (add a 'wishlist_MYIDEA' page if you need more space!)
    * If it's an actual bug [create a new issue](https://github.com/CPAN-API/metacpan-web/issues/new)

## Contributing code

Come talk to us on IRC (see below), or send a pull request and we'll respond
there.  If you implement a new feature, please add a note about it to the
News.md file at the top level of metacpan-web so that it will appear in our
news feed.

If you aren't using the VM, remember to enable the pre-commit hook before you start working.

    sh git/setup.sh

These links will get you going quickly:

  * [Using our developer VM](https://github.com/CPAN-API/metacpan-developer) to get you going in minutes (depending on bandwidth)
  * [Front end bug list](https://github.com/CPAN-API/metacpan-web/issues)
  * [API (back end) bug list](https://github.com/CPAN-API/cpan-api/issues)
  * [Wishlist](https://github.com/CPAN-API/cpan-api/wiki/Wishlist) - things that probably need doing

# Git workflow

We try to keep a clean git history, so if it all possible, please rebase to get
the latest changes from master _before_ submitting a pull request.  You'll only
need to do the first command (git remote add) once in your local checkout.

    git remote add upstream https://github.com/CPAN-API/metacpan-web.git
    git pull --rebase upstream master

If you are comfortable rebasing, it is also helpful to squash or delete commits
which are no longer relevant to your branch before submitting your work.

    git rebase -i master

If you are not comfortable with rebasing, but want to use it, check out the steps
from [here](https://help.github.com/articles/using-git-rebase/).

# Coding conventions

Please try to follow the conventions already been used in the code base.  This
will generally be the right thing to do.  Our standards are improving, so even
if you do follow what you see, we may ask you to make some changes, but that is
a good thing.  We are trying to keep things tidy.

If you are using the [developer VM](https://github.com/CPAN-API/metacpan-developer) you can run:

```sh
/home/vagrant/carton/metacpan-web/bin/tidyall
```

## Perl Best Practices

In general, the concepts discussed in "Perl Best Practices" are a good starting
point.  Use autodie where possible and MetaCPAN::Web::Types when creating new
Moose attributes.  Many of the other standards will be enforced by Perl::Critic.

## Clear > Concise

Take pains to use variable names which are easy to understand and to write
readable code.  We value readable code over concise code.  Use singular nouns
for class names.  Use verbs for method names.

## Try::Tiny > eval { ... }

You will see many eval statements in the code.  We would like to standardize on
Try::Tiny, so feel free to swap out any eval with a Try::Tiny and use Try::Tiny
in all new code.

## Prefer single quotes

Always use single quotes in cases where there is no variable interpolation.  If
there is a single quote in the quoted item, use curly quotes.

q{Isn't this a lovely day};

## Include a test (or more!)

Any time when a pull request includes a test, it makes it easier for us to
review and accept, so please do test your changes whenever possible.  If your
pull request includes visual changes, please include a before and after screen
shot, so that we can better understand the problem you're trying to solve.

## Dependencies

Introducing new dependencies is fine, if they solve a specific problem which
current dependencies cannot address.  If we prefer a different module to be used,
we'll let you know.

## It's OK to be controversial

If a pull request contains any controversial changes, we'll likely wait for some
feedback from several developers before a merge.  If you think your changes may
be controversial, feel free to discuss them in a Github issue before starting to
write any code.

## Travis is your friend

We use Travis to test all code changes.  After submitting your pull request,
remember to check back to see whether Travis has come back with any test
failures.  We do get some false negatives.  If your pull request failed for
reasons unrelated to your changes, we may still be able to merge your work.

# Additional Resources

  * [\#metacpan](http://widget01.mibbit.com/?autoConnect=true&server=irc.perl.org&channel=%23metacpan&nick=) IRC channel on irc.perl.org

# Current Policies

### What is indexed?

 * Perl distributions which contain Perl packages.

### When are issues closed?

We want to keep the issue list manageable, so we can focus on what actually
needs fixing.  If you feel an issue needs opening again, please add a comment
explaining why it needs re-opening and we'll look at it again.

 * Issues will be closed and moved to [Wishlist](https://github.com/CPAN-API/cpan-api/wiki/Wishlist) if they are not actual bugs
 * Issues we think we have addressed will be closed
 * Issues we are not going to take any further action on without more information will be closed
