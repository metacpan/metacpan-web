function Github() {
    // anchor patterns and check for www. or no subdomain to avoid user wikis, blogs, etc
    return {
        config: {
            issues: {
                pattern: /^(?:https?:\/\/)?(?:www\.)?github\.com\/([^\/]+)\/([^\/]+)\/issues\/?$/,
                prepareData: function(self, data, cb) {
                    // we need additionally the repo info
                    var url = self.url.replace('/issues', '');
                    $.getJSON(url, function(repo) {
                        cb({
                            issues: data,
                            repo: repo.data
                        });
                    });
                },
                render: function(self, data) {
                    if (data.issues.length == 0) {
                        return 'There are currently no open issues.';
                    }

                    var result = '<table>'
                                +'  <tr><th>Open <a href="'+ data.repo.html_url +'/issues">Issues</a>:</th><td>'+ data.repo.open_issues +'</td></tr>'
                                +'  <tr><th>Last 15 Issues:</th><td><table>';

                    $.each(data.issues, function(idx, row) {
                        result += '<tr><td><span class="relatize">'+ row.created_at +'</span></td><td><a href="'+ row.html_url +'">'+ row.title +'</a></td></tr>'
                    });

                    return result +'</table></td></tr></table>';
                },
                url: function(self, result) {
                    return self.githubApiUrl +'/repos/'+ result[1] +'/'+ result[2] +'/issues?per_page=15&callback=?';
                }
            },
            repo: {
                pattern: /^(?:(?:git|https?):\/\/)?(?:www\.)?github\.com(?:\/|:)([^\/]+)\/([^\/\.]+)(?:\/|\.git)*$/,
                render: function(self, data) {
                    return   '<table>'

                            +( data.description
                            ?'  <tr><th>Description:</th><td>'+ data.description +'</td></tr>'
                            :'' )

                            +( data.homepage
                            ?'  <tr><th>Homepage:</th><td><a href="'+ data.homepage +'">'+ data.homepage +'</a></td></tr>'
                            :'' )

                            // with v3 api the number under 'watchers' is actually the number of stargazers
                            // in the v4 api this will be corrected. see https://github.com/CPAN-API/metacpan-web/issues/975
                            +'  <tr><th>Stars:</th><td><a href="'+ data.html_url +'/stargazers">'+ data.watchers +'</a></td></tr>'
                            +'  <tr><th>Forks:</th><td><a href="'+ data.html_url +'/network">'+ data.forks +'</a></td></tr>'

                            +( data.has_issues
                            ?'  <tr><th>Open <a href="'+ data.html_url +'/issues">Issues</a>:</th><td>'+ data.open_issues +'</td></tr>'
                            :'' )

                            +'  <tr><th>Clone URL:</th><td><a href="'+ data.clone_url +'">'+ data.clone_url +'</a></td></tr>'
                            +'  <tr><th>Git URL:</th><td><a href="'+ data.git_url +'">'+ data.git_url +'</a></td></tr>'
                            +'  <tr><th>Github URL:</th><td><a href="'+ data.html_url +'">'+ data.html_url +'</a></td></tr>'
                            +'  <tr><th>SSH URL:</th><td><a href="'+ data.ssh_url.replace(/^(\w+\@)?([^:\/]+):/,'ssh://$1$2/') +'">'+ data.ssh_url +'</a></td></tr>'
                            +'  <tr><th>Last Commit:</th><td><span class="relatize">'+ data.pushed_at +'</span></td></tr>'
                            +'</table>';
                },
                url: function(self, result) {
                    return self.githubApiUrl +'/repos/'+ result[1] +'/'+ result[2] +'?callback=?';
                }
            },
            user: {
                pattern: /^(?:https?:\/\/)?(?:www\.)?github\.com\/([^\/]+)\/?$/,
                render: function(self, data) {
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
                url: function(self, result) {
                    return self.githubApiUrl +'/users/'+ result[1] +'?callback=?';
                }
            }
        },

        githubApiUrl: 'https://api.github.com',
        githubUrl: 'https://github.com',
        item: null,
        type: null,
        url: null,

        createPopup: function(item) {
            this.item = $(item);

            if ( !this.parseUrl() ) {
                return;
            }

            var self = this;

            this.item.qtip({
                content: {
                    ajax: {
                        dataType: 'json',
                        type: 'GET',
                        url: this.url,
                        success: function(res, status) {
                            var qtip = this;
                            var data = self.prepareData(res.data, function(data) {
                                var html = self.render(data);
                                qtip.set('content.text', html);
                                $('.qtip-github .relatize').each(function() {
                                    if ( !$(this).hasClass('relatized') ) {
                                        $(this).relatizeDate();
                                        $(this).addClass('relatized');
                                    }
                                });
                            });
                        }
                    },
                    text: '<img src="/static/icons/busy.gif" />',
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
                    classes: 'ui-tooltip-rounded ui-tooltip-shadow ui-tooltip-light'
                }
            });
        },

        hasGithubUrl: function() {
            return this.item.attr('href').match('github');
        },

        // This loops over the keys/values found in this.config and
        // executes the regular expression pattern found there
        // against the href attribute. If any of the regular
        // expressions matches, it will return true and stop
        // executing any other regular expressions.
        parseUrl: function() {
            if (!this.hasGithubUrl()) {
                return false;
            }
            var self = this;
            $.each(this.config, function(type, config) {
                var result = config.pattern.exec(self.item.attr('href'));
                if (result) {
                    self.url = config.url(self, result);
                    self.type = type;
                    return false;
                }
            });
            if (this.type === null) {
                return false;
            }
            return true;
        },

        prepareData: function(data, cb) {
            if (typeof this.config[this.type].prepareData === 'function') {
                this.config[this.type].prepareData(this, data, cb);
            }
            else {
                cb(data);
            }
        },

        render: function(data) {
            return '<div class="qtip-github">'+ this.config[this.type].render(this, data) +'</div>';
        }
    }
};

$(document).ready(function() {
    $('.nav-list a:not(.nopopup)').each(function() {
          var github = new Github();
          github.createPopup(this);
    });
});
