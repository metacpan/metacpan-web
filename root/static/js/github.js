/*global document,$ */
(function(){

    // TODO: In some cases there are separate web/clone urls, but they resolve
    // to the same github repo.  If you mouse over both the requests are made
    // twice.  It would be nice to share the responses between both.

    function GitHubUrl(item) {
        this.item = $(item);
        this.href = this.item.attr('href');
    }

    GitHubUrl.match = function(a){
        if ($(a).length == 0) return;

        return $(a).attr('href').indexOf('github') >= 0;
    };

    // anchor patterns and check for www. or no subdomain to avoid user wikis, blogs, etc

    $.extend(GitHubUrl.prototype, {
        config: {

            // Release info
            issues: {
                pattern: /^(?:https?:\/\/)?(?:www\.)?github\.com\/([^\/]+)\/([^\/]+)\/issues\/?$/,
                prepareData: function(data, cb) {
                    // we need additionally the repo info
                    var url = this.url.replace('/issues', '');
                    $.getJSON(url, function(repo) {
                        cb({
                            issues: data,
                            repo: repo
                        });
                    });
                },
                render: function(data) {
                    if (data.issues.length === 0) {
                        return 'There are currently no open issues.';
                    }

                    var issues_text = 'Last 15 Issues';
                    if (data.issues.length <= 15) {
                        issues_text = 'Issues';
                    }

                    var result = '<table>'
                                +'  <tr><th>Open <a href="'+ data.repo.html_url +'/issues">Issues</a>:</th><td>'+ data.repo.open_issues +'</td></tr>'
                                +'  <tr><th>' + issues_text + ':</th><td><table>';

                    $.each(data.issues, function(idx, row) {
                        result += '<tr><td><span class="relatize">'+ row.created_at +'</span></td><td><a href="'+ row.html_url +'">'+ row.title +'</a></td></tr>';
                    });

                    return result +'</table></td></tr></table>';
                },
                url: function(result) {
                    return this.githubApiUrl +'/repos/'+ result[1] +'/'+ result[2] +'/issues?per_page=15';
                }
            },

            // Release info
            repo: {
                // NOTE: Not allowing dots in the repo name might be too restrictive.
                pattern: /^(?:(?:git|https?):\/\/)?(?:www\.)?github\.com(?:\/|:)([^\/]+)\/([^\/\.]+)(?:\/(tree(?:\/master)?)?|\.git)*$/,
                normalizeUrl: function(match){
                    // Old releases might have old github urls ("/$user/$repo/tree").
                    // Since github doesn't honor those anymore, fix the link.
                    // A url like ".../tree/master" still seems to work, though.
                    if( match[3] === 'tree' ){
                        this.item.attr('href', this.href.replace(/\/tree$/, ''));
                    }
                },
                render: function(data) {
                    return   '<table>'

                            +( data.description
                            ?'  <tr><th>Description:</th><td>'+ data.description +'</td></tr>'
                            :'' )

                            +( data.homepage
                            ?'  <tr><th>Homepage:</th><td><a href="'+ data.homepage +'">'+ data.homepage +'</a></td></tr>'
                            :'' )

                            // with v3 api the number under 'watchers' is actually the number of stargazers
                            // in the v4 api this will be corrected. see https://github.com/metacpan/metacpan-web/issues/975
                            +'  <tr><th>Stars:</th><td><a href="'+ data.html_url +'/stargazers">'+ data.watchers +'</a></td></tr>'
                            +'  <tr><th>Forks:</th><td><a href="'+ data.html_url +'/network">'+ data.forks +'</a></td></tr>'

                            +( data.has_issues
                            ?'  <tr><th>Open Issues: </th><td><a href="'+ data.html_url +'/issues">'+ data.open_issues +'</a></td></tr>'
                            :'' )

                            +'  <tr><th>Pull Requests:</th><td><a href="'+ data.html_url +'/pulls">'+ data.html_url + '/pulls' + '</a></td></tr>'
                            +'  <tr><th>Clone URL:</th><td><a href="'+ data.clone_url +'">'+ data.clone_url +'</a></td></tr>'
                            +'  <tr><th>Git URL:</th><td><a href="'+ data.git_url +'">'+ data.git_url +'</a></td></tr>'
                            +'  <tr><th>Github URL:</th><td><a href="'+ data.html_url +'">'+ data.html_url +'</a></td></tr>'
                            +'  <tr><th>SSH URL:</th><td><a href="'+ data.ssh_url.replace(/^(\w+\@)?([^:\/]+):/,'ssh://$1$2/') +'">'+ data.ssh_url +'</a></td></tr>'
                            +'  <tr><th>Last Commit:</th><td><span class="relatize">'+ data.pushed_at +'</span></td></tr>'
                            +'</table>';
                },
                url: function(result) {
                    return this.githubApiUrl +'/repos/'+ result[1] +'/'+ result[2];
                }
            },

            // Author profiles
            user: {
                pattern: /^(?:https?:\/\/)?(?:www\.)?github\.com\/([^\/]+)\/?$/,
                render: function(data) {
                    return   '<table>'
                            +( data.name
                            ?'  <tr><th>Name:</th><td>'+ data.name +'</td></tr>'
                            :'' )

                            +( data.email
                            ?'  <tr><th>Email:</th><td><a href="mailto:'+ data.email +'">'+ data.email +'</a></td></tr>'
                            :'' )

                            +( data.blog
                            ?'  <tr><th>Website/Blog:</th><td><a href="'+ data.blog +'">'+ data.blog +'</a></td></tr>'
                            :'' )

                            +( data.company
                            ?'  <tr><th>Company:</th><td>'+ data.company +'</td></tr>'
                            :'' )

                            +( data.location
                            ?'  <tr><th>Location:</th><td>'+ data.location +'</td></tr>'
                            :'' )

                            +'  <tr><th>Member Since:</th><td><span class="relatize">'+ data.created_at +'</span></td></tr>'
                            +'  <tr><th><a href="'+ data.html_url +'/followers">Followers</a>:</th><td>'+ data.followers +'</td></tr>'
                            +'  <tr><th><a href="'+ data.html_url +'/following">Following</a>:</th><td>'+ data.following +'</td></tr>'
                            +'  <tr><th><a href="'+ data.html_url +'/repositories">Public Repos</a>:</th><td>'+ data.public_repos +'</td></tr>'
                            +'</table>';
                },
                url: function(result) {
                    return this.githubApiUrl +'/users/'+ result[1];
                }
            }
        },

        githubApiUrl: 'https://api.github.com',
        githubUrl: 'https://github.com',

        createPopup: function() {

            if ( !this.parseUrl() ) {
                return;
            }

            var self = this;
            var qtip;
            var tooltip = this.item.qtip({
                content: {
                    ajax: {
                        dataType: 'json',
                        type: 'GET',
                        url: this.url,
                        error: function(data) {
                            var error = (data && data.message) || 'An error occurred';
                            qtip.set('content.text', '<i>' + error + '</i>');
                        },
                        success: function(data) {
                            self.prepareData(data, function(data) {
                                var html = self.render(data);
                                qtip.set('content.text', html);
                                $('.qtip-github .relatize').each(function() {
                                    if ( !$(this).hasClass('relatized') ) {
                                        $(this).relatizeDate();
                                        $(this).addClass('relatized');
                                    }
                                });
                            });
                        },
                    },
                    text: '<i class="fa fa-spinner fa-spin"></i>',
                    title: 'Github Info'
                },
                hide: {
                    event: 'mouseleave',
                    fixed: true
                },
                position: {
                    at: 'right center',
                    my: 'left center'
                },
                style: {
                    classes: 'qtip-shadow qtip-rounded qtip-light qtip-github',
                }
            });
            qtip = tooltip.qtip('api');
        },

        // This loops over the keys/values found in this.config and
        // executes the regular expression pattern found there
        // against the href attribute. If any of the regular
        // expressions matches, it will return true and stop
        // executing any other regular expressions.
        parseUrl: function() {
            var self = this;
            $.each(this.config, function(type, config) {
                var result = config.pattern.exec(self.href);
                if (result) {
                    if( config.normalizeUrl ){
                        config.normalizeUrl.call(self, result);
                    }
                    self.url = config.url.call(self, result);
                    self.type = type;
                    return false;
                }
            });
            if (this.type) {
                return true;
            }
            return false;
        },

        prepareData: function(data, cb) {
            if (typeof this.config[this.type].prepareData === 'function') {
                this.config[this.type].prepareData.call(this, data, cb);
            }
            else {
                cb(data);
            }
        },

        render: function(data) {
            try {
                return this.config[this.type].render.call(this, data);
            }
            catch(x) {
                // Don't let the spinner spin forever.
                return '<i>Error</i>';
            }
        }
    });

$(document).ready(function() {
    $('.nav-list a:not(.nopopup)').each(function() {
        if( GitHubUrl.match(this) ) {
            (new GitHubUrl(this)).createPopup();

        }
    });

    var repository = $('a[data-keyboard-shortcut="g r"]');

    if( GitHubUrl.match(repository) ) {
        Mousetrap.bind('g p', function() {
            // we haven't hit the github api at this point, so we cheat for the url
            var pull_request_url = repository.attr('href') + '/pulls';
            window.location = pull_request_url;
        });
    }
});

}());
