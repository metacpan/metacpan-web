function Github() {
    return {
        githubApiUrl: 'https://api.github.com',
        githubUrl: 'https://github.com',
        item: null,
        user: null,
        repo: null,
        result: null,

        createPopup: function(item) {
            var me = this;
            this.item = $(item);

            // parse user and repo name
            if (!this.parseUrl()) {
                return;
            }

            var url = this.githubApiUrl +'/repos/'+ this.user +'/'+ this.repo +'?callback=?';

            this.item.mouseover(function() {
                if (me.result) {
                    me.showPopup();
                    return;
                }

                me.showPopup();
                $.getJSON(url, function(json) {
                    me.result = json;
                    me.showPopup();
                });
            });
        },

        showPopup: function() {
            var content = '<img src="/static/icons/busy.gif" />';

            if (this.result) {
                content = '<table class="release-info-github">'

                         + ( this.result.data.description
                         ? '  <tr><th>Description:</th><td>'+ this.result.data.description +'</td></tr>'
                         : '' )

                         + ( this.result.data.homepage
                         ? '  <tr><th>Homepage:</th><td><a href="'+ this.result.data.homepage +'">'+ this.result.data.homepage +'</a></td></tr>'
                         : '' )

                         +'  <tr><th><a href="'+ this.result.data.html_url +'/watchers">Watchers</a>:</th><td>'+ this.result.data.watchers +'</td></tr>'
                         +'  <tr><th><a href="'+ this.result.data.html_url +'/network">Forks</a>:</th><td>'+ this.result.data.forks +'</td></tr>'
                         +'  <tr><th>Open <a href="'+ this.result.data.html_url +'/issues">Issues</a>:</th><td>'+ this.result.data.open_issues +'</td></tr>'
                         +'  <tr><th>Clone URL:</th><td><a href="'+ this.result.data.clone_url +'">'+ this.result.data.clone_url +'</a></td></tr>'
                         +'  <tr><th>Git URL:</th><td><a href="'+ this.result.data.git_url +'">'+ this.result.data.git_url +'</a></td></tr>'
                         +'  <tr><th>Github URL:</th><td><a href="'+ this.result.data.html_url +'">'+ this.result.data.html_url +'</a></td></tr>'
                         +'  <tr><th>SSH URL:</th><td><a href="ssh://'+ this.result.data.ssh_url +'">'+ this.result.data.ssh_url +'</a></td></tr>'
                         +'  <tr><th>Last Commit:</th><td><span class="relatize">'+ this.result.data.pushed_at +'</span></td></tr>'
                         +'</table>';
            }

            if (this.item.IsBubblePopupOpen()) {
                this.item.SetBubblePopupInnerHtml(content, false);
            }
            else {
                this.item.CreateBubblePopup({
                    align: 'middle',
                    innerHtml: content,
                    innerHtmlStyle: { 'text-align':'center' },
                    position: 'right',
                    selectable: true,
                    themeName: 'grey',
                    themePath: '/static/images/jquerybubblepopup-theme'
                });
            }
            $('.jquerybubblepopup .relatize').relatizeDate();
        },

        parseUrl: function() {
            var re = new RegExp(/github\.com\/([^\/]+)\/([^\/\.]+)/);
            var result = re.exec(this.item.attr('href'));
            if (result && result[1] && result[2]) {
                this.user = result[1];
                this.repo = result[2];
                return true;
            }
            return false;
        },
    }
};

$(document).ready(function() {
    $('#release-info-repository a').each(function() {
        var github = new Github();
        github.createPopup(this);
    });
});