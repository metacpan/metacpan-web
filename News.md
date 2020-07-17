Title: Source code permalinks are here
------------------------------
Date: 2020-03-29T00:00:00

Versioned permalinks from source code pages are [now available](https://twitter.com/metacpan/status/1244677954275336200)

Title: Rendering .md files
------------------------------
Date: 2019-10-18T01:54:00

We're now rendering .md files as HTML instead of as raw code.

Title: The traffic is coming
------------------------------
Date: 2018-12-02T19:30:00

As [announced](https://log.perl.org/2018/05/goodbye-search-dot-cpan-dot-org.html)
in the Perl NOC, search.cpan.org is going to redirect all traffic to MetaCPAN
from 25th of June 2018. We are doing lots of work to prepare for this
trebling of traffic.

Title: MetaHack 2
------------------------------
Date: 2017-11-02T19:30:00

http://www.olafalders.com/2017/10/12/announcing-metahack-v2/

https://metacpan.org/about/meta_hack

http://blogs.perl.org/users/leo_lapworth/2017/11/metahack-2.html




Title: SSL improvements
------------------------------
Date: 2014-12-02T19:30:00

Our servers have had their SSL configuration upgraded,
so we now get an A rating on [SSL Labs](https://www.ssllabs.com/ssltest/analyze.html?d=fastapi.metacpan.org).

[Fastly](https://www.fastly.com) who serve all our content
other than the [api](https://fastapi.metacpan.org/) already had
tight configs... and now so do we. I'd like to thank then for providing
both examples, support and an IRC channel where Donald Stufft
from the Python infrastructure team was able to help out.

All our configs and systems are in our [github repos](https://github.com/metacpan/)
so feel free to review / improve or 'borrow' configs from.

Title: Liquid Web is Sponsoring MetaCPAN
------------------------------
Date: 2014-11-08T03:00:00

We're immensely pleased to announce that [Liquid Web
Inc.](https://www.liquidweb.com/) is our newest hosting sponsor.  This
sponsorship entails 3 powerful machines which are provided and co-located by
Liquid Web Inc.  Having access to this hardware will allow us greater
redundancy in addition to giving us powerful machines to use as a staging area
when developing new MetaCPAN features.  This is a huge development for us and
we'd like to thank Liquid Web Inc. for this very kind donation.  More details
to come!

Title: Server move - phase 2
------------------------------
Date: 2014-10-21T19:00:00

We have moved all sites over to [Fastly](https://www.fastly.com)
(where possible) and they are backed up by the new
[Bytemark](https://www.bytemark.co.uk/) servers.

We have further plans... but this will do for now,
many thanks to our sponsors for making this possible.

[network-infrastructure](https://github.com/metacpan/network-infrastructure)
and [metacpan-puppet](https://github.com/metacpan/metacpan-puppet) have all
our configs if you want to see details of anything.


Title: Server move - phase 1
------------------------------
Date: 2014-09-19T19:00:00

We are moving servers, [Bytemark](https://www.bytemark.co.uk/) have
asked for the old one back... and given us 2 new ones in replacement!

We are moving as much as possible to [Fastly](https://www.fastly.com) CDN
which makes switching origins very easy, and instant.

So far we have moved...

* http(s)://cpan.metacpan.org/
* http://explorer.metacpan.org/
* http://search.mcpan.org/
* http://mcpan.org/

We will be documenting this a bit more under [Network Infrastructure](https://github.com/metacpan/network-infrastructure)
but that's a work in progress.


Title: Let's move to Bootstrap 3
------------------------------
Date: 2014-08-06T08:55:22

MetaCPAN has moved to Bootstrap 3 as well as introducing cool icons from [Font Awesome](http://fortawesome.github.io/Font-Awesome/). Let's make MetaCPAN be more colorful!

Title: Link to Task::Kensho is now available on home page and no result page
------------------------------
Date: 2014-06-14T23:25:11

If you’re absolute newbies who're not even sure what to search, it will be good idea to take a look at [Task::Kensho!](https://metacpan.org/pod/Task::Kensho) We provide a link to the module in both Home page and No result page with the idea to help CPAN beginners to get started.

Title: Faster with Fastly
------------------------------
Date: 2014-06-14T18:44:15

You may have noticed an increase in speed for https://metacpan.org/
since the 22nd of May, this is because the site is now served
through [Fastly](https://www.fastly.com/). Fastly are providing this
service free of charge. We are not fully utilising is yet (we don't
let Fastly cache much), but it makes all sorts of things easier
for us and we will be able to do even more for you with it in the future.

Title: Suggestion on incorrect number of colons
------------------------------
Date: 2014-06-09T08:15:00

Perl module name should contain only 2 colons, some common mistakes are we underuse or overuse it. Now, suggestion on no result page available when search with missing colon such as [Test:More](https://metacpan.org/search?q=Test%3AMore) or too much colons like [DBIx:::Class::::ResultSet](https://metacpan.org/search?q=DBIx%3A%3A%3AClass%3A%3A%3A%3AResultSet).

Title: Table sorting is now persistent
------------------------------
Date: 2014-05-19T10:50:12

When you change the sorting of a table it will be saved in your
browser's localStorage so that the next time you view that particular table
it will remember your last preference.  This is saved on a per table basis
(for example, author releases, author favorites, and reverse dependency releases).
No need to set it every time when accessing that page in the same browser.

Title: Details of (++)plussers displayed
------------------------------
Date: 2014-05-12T18:40:17

To get a better insight of which Pause users have ++ed a particular distribution, a list of their gravatar images is displayed.
Also, the count of non-Pause plussers makes it easier to know how many users have liked the module.

Hence, it gives us a perception of the people who recommend the module.


Title: Dependency Graphs are Here
------------------------------
Date: 2014-05-13T20:50:10

Jeffrey Thalhammer took the time this week to contribute dependency graphs to
MetaCPAN.  The graphs are hosted by [Stratopan](https://stratopan.com) and they
can be found on module and release pages under the "Reverse Dependencies" link.

Thanks very much to [THALJEF](https://metacpan.org/author/THALJEF) for
implementing this new feature.


Title: News feed of MetaCPAN created
------------------------------
Date: 2014-04-15T21:10:10


In this news feed you can follow the development of the MetaCPAN site.
There is also an [Atom feed](/feed/news).

If you are interested in how the news feed itself was implemented, check out
the article [Adding a News Feed to
MetaCPAN](https://perlmaven.com/adding-news-feed-to-metacpan)
