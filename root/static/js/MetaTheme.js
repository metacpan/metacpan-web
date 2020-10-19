(function (window) {
	var Theme = function () {
		return this;
	};

	Theme.prototype = {
		loaded: false,
		fonts: [
			{ name: "'Helvetica Neue', Helvetica, Arial, sans-serif" },
			{ name: "Menlo, Monaco, 'DejaVu Sans Mono', Consolas, 'Bitstream Vera Sans Mono', Courier, 'Courier New', monospace" },	
			{ name: "OpenDyslexic2, OpenDyslexic", otf: "/static/fonts/OpenDyslexic-Regular.otf" },
			{ name: "Montez", url: "https://fonts.googleapis.com/css?family=Montez" },
			{ name: "Lobster", url: "https://fonts.googleapis.com/css?family=Lobster" },
			{ name: "Josefin Sans", url: "https://fonts.googleapis.com/css?family=Josefin+Sans" },
			{ name: "Shadows Into Light", url: "https://fonts.googleapis.com/css?family=Shadows+Into+Light"},
			{ name: "Pacifico", url: "https://fonts.googleapis.com/css?family=Pacifico" },
			{ name: "Amatic SC", url: "https://fonts.googleapis.com/css?family=Amatic+SC" },
			{ name: "Orbitron",  url: "https://fonts.googleapis.com/css?family=Orbitron" }, 
			{ name: "Roboto", url: "https://fonts.googleapis.com/css?family=Roboto" },
			{ name: "Rokkitt", url: "https://fonts.googleapis.com/css?family=Rokkitt" },
			{ name: "Righteous", url: "https://fonts.googleapis.com/css?family=Righteous" },
			{ name: "Dancing Script", url: "https://fonts.googleapis.com/css?family=Dancing+Script" },
			{ name: "Bangers", url: "https://fonts.googleapis.com/css?family=Bangers" },
			{ name: "Chewy", url: "https://fonts.googleapis.com/css?family=Chewy" },
			{ name: "Sigmar One", url: "https://fonts.googleapis.com/css?family=Signer+One" },
			{ name: "Architects Daughter", url: "https://fonts.googleapis.com/css?family=Architects+Daughter" },
			{ name: "Abril Fatface", url: "https://fonts.googleapis.com/css?family=Abril+Fatface" },
			{ name: "Covered By Your Grace", url: "https://fonts.googleapis.com/css?family=Covered+By+Your+Grace" },
			{ name: "Kaushan Script", url: "https://fonts.googleapis.com/css?family=Kaushan+Script" },
			{ name: "Gloria Hallelujah", url: "https://fonts.googleapis.com/css?family=Gloria+Hallelujah" },
			{ name: "Satisfy", url: "https://fonts.googleapis.com/css?family=Satisfy" },
			{ name: "Lobster Two", url: "https://fonts.googleapis.com/css?family=Lobster+Two" },
			{ name: "Comfortaa", url: "https://fonts.googleapis.com/css?family=Comfortaa" },
			{ name: "Cinzel", url: "https://fonts.googleapis.com/css?family=Cinzel" },
			{ name: "Courgette", url: "https://fonts.googleapis.com/css?family=Courgette" },
			{ name: "Oswald", url: "https://fonts.googleapis.com/css?family=Oswald" },
		],
		fontFamilySelectors: [
			'body_font_family',
			'syntax_font_family',
		],
		fontSizeSelectors: [
			'body_font_size',
			'input_font_size',
			'h1_font_size',
			'h2_font_size',
			'h3_font_size',
			'h4_font_size',
			'h5_font_size',
			'h6_font_size'
		],
		fontDefaults: {
			'body_font_family': { name: "'Helvetica Neue', Helvetica, Arial, sans-serif" },
			'syntax_font_family': { name: "Menlo, Monaco, 'DejaVu Sans Mono', Consolas, 'Bitstream Vera Sans Mono', Courier, 'Courier New', monospace" },
			'body_font_size': '13',
			'input_font_size': '14',
			'h1_font_size': '33',
			'h2_font_size': '27',
			'h3_font_size': '23',
			'h4_font_size': '17',
			'h5_font_size': '13',
			'h6_font_size': '12'
		},
		colorSelectors: [
			'main_background_color',
			'main_font_color',
			'main_second_font_color',
			'main_border_color',
			'main_box_shadow_color',
			'main_text_shadow_color',
			'main_hover_background_color',
			'secondary_background_color',
			'secondary_font_color',
			'nav_background_color',
			'nav_border_color',
			'nav_font_color',
			'nav_selected_color',
			'nav_selected_font_color',
			'nav_selected_border_color',
			'nav_selected_box_shadow_color',
			'nav_hover_background_color',
			'nav_hover_font_color',
			'nav_hover_border_color',
			'nav_side_selected_color',
			'nav_side_selected_font_color',
			'nav_side_hover_background_color',
			'input_background_color',
			'input_font_color',
			'input_border_color',
			'input_focus_border_color',
			'input_focus_box_shadow_color',
			'btn_background_color',
			'btn_secondary_background_color',
			'btn_third_background_color',
			'btn_font_color',
			'btn_border_color',
			'btn_hover_background_color',
			'link_font_color',
			'link_hover_font_color',
		        'syntax_keyword_color',
			'syntax_plain_color',
			'syntax_functions_color',
			'syntax_string_color',
			'syntax_comments_color',
			'syntax_variable_color',
			'syntax_border_color',
			'syntax_line_number_color',
			'syntax_hover_line_number_color',
			'syntax_selected_line_background_color',
			'activity_background_color',
			'primary_background_color',
			'primary_font_color',
			'primary_border_color',
			'primary_hover_background_color',
			'primary_hover_font_color',
			'primary_hover_border_color',
			'warning_background_color',
			'warning_font_color',
			'warning_border_color',
			'warning_hover_background_color',
			'warning_hover_font_color',
			'warning_hover_border_color',
			'success_background_color',
			'success_font_color',
			'success_border_color',
			'success_hover_background_color',
			'success_hover_font_color',
			'success_hover_border_color',
			'danger_background_color',
			'danger_font_color',
			'danger_border_color',
			'danger_hover_background_color',
			'danger_hover_font_color',
			'danger_hover_border_color',
			'info_background_color',
			'info_font_color',
			'info_border_color',
			'info_hover_background_color',
			'info_hover_font_color',
			'info_hover_border_color',
			'alert_success_background_color',
			'alert_success_font_color',
			'alert_success_border_color',
			'alert_success_link_color',
			'alert_warning_background_color',
			'alert_warning_border_color',
			'alert_warning_font_color',
			'alert_warning_link_color',
			'alert_info_background_color',
			'alert_info_border_color',
			'alert_info_font_color',
			'alert_info_link_color',
			'alert_danger_background_color',
			'alert_danger_border_color',
			'alert_danger_font_color',
			'alert_danger_link_color'
		],
		dark: {
			logo: '/static/images/metacpan-logo-light.png',
			main_background_color: '#333639',
			main_font_color: '#dadada',
			main_second_font_color: '#cacaca',
			main_border_color: '#1f2225',
			main_box_shadow_color: '#5b5e61',
			main_text_shadow_color: 'rgba(91, 94, 97, 0.75)',
			main_hover_background_color: '#1f2325',
			secondary_background_color: '#3d4043',
			secondary_font_color: '#dadada',
			nav_background_color: '#1f2225',
			nav_border_color: '#292c2f',
			nav_font_color: '#dadada',
			nav_selected_color: '#333639',
			nav_side_selected_color: '#1f2226',
			nav_side_selected_font_color: '#ffffff',
			nav_side_hover_background_color: '#1f2225',
			nav_selected_font_color: '#ffffff',
			nav_selected_border_color: '#3d4043',
			nav_selected_box_shadow_color: '#3d4043',
			nav_hover_font_color: '#ffffff',
			nav_hover_border_color: '#ffffff',
			nav_hover_background_color: '#1f2225',
			input_background_color: '#1f2225',
			input_font_color: '#dadada',
			input_border_color: '#282c2f',
			input_focus_border_color: '#3d4043',
			input_focus_box_shadow_color: '#717171',
			btn_background_color: '#292c2f',
			btn_secondary_background_color: 'rgba(41, 44, 47, 0.5)',
			btn_third_background_color: 'rgba(31, 34, 37, 0.8)',
			btn_font_color: '#dadada',
			btn_border_color: '#14181b',
			btn_hover_background_color: '#14181b',
			link_font_color: '#ffffff',
			link_hover_font_color: '#fcfcfc',
		        syntax_keyword_color: '#8fc9e6',
			syntax_plain_color: '#dadada',
			syntax_functions_color: '#8fc9e6',
			syntax_string_color: '#9393ff',
			syntax_comments_color: '#6efb6e',
			syntax_variable_color: '#f3c968',
			syntax_border_color: '#292c2f',
			syntax_line_number_color: '#ff5050',
			syntax_hover_line_number_color: '#ff7f7f',
			syntax_selected_line_background_color: '#1e2224',
			activity_background_color: '#dadada',
			warning_background_color: '#f0ad4e',
			warning_font_color: '#ffffff',
			warning_border_color: '#eea236',
			warning_hover_background_color: '#ec971f',
			warning_hover_font_color: '#ffffff',
			warning_hover_border_color: '#d58512',
			primary_background_color: '#337ab7',
			primary_font_color: '#ffffff',
			primary_border_color: '#2e6da4',
			primary_hover_background_color: '#286090',
			primary_hover_font_color: '#ffffff',
			primary_hover_border_color: '#204d74',
			success_background_color: '#5cb85c',
			success_font_color: '#ffffff',
			success_border_color: '#4cae4c',
			success_hover_background_color: '#449d44',
			success_hover_font_color: '#ffffff',
			success_hover_border_color: '#398439',
			danger_background_color: '#d9534f',
			danger_font_color: '#ffffff',
			danger_border_color: '#d43f3a',
			danger_hover_background_color: '#c9302c',
			danger_hover_font_color: '#ffffff',
			danger_hover_border_color: '#ac2925',
			info_background_color: '#5bc0de',
			info_font_color: '#ffffff',
			info_border_color: '#46b8da',
			info_hover_background_color: '#31b0d5',
			info_hover_font_color: '#ffffff',
			info_hover_border_color: '#269abc',
			alert_success_background_color: '#d7f5dd',
			alert_success_font_color: '#333333',
			alert_success_border_color: '#d6e9c6',
			alert_success_link_color: '#337ab7',
			alert_warning_background_color: '#f5efd7',
			alert_warning_font_color: '#333333',
			alert_warning_border_color: '#faebcc',
			alert_warning_link_color: '#337ab7',
			alert_info_background_color: '#d7e1f5',
			alert_info_font_color: '#333333',
			alert_info_border_color: '#4083a3',
			alert_info_link_color: '#337ab7',
			alert_danger_background_color: '#f2dede',
			alert_danger_font_color: '#333333',
			alert_danger_border_color: '#ebccd1',
			alert_danger_link_color: '#337ab7'
		},
		light: {
			logo: '/static/images/metacpan-logo@2x.png',
			main_background_color: '#ffffff',
			main_font_color: '#333333',
			main_second_font_color: '#545454',
			main_border_color: '#e5e5e5',
			main_box_shadow_color: '#cccccc',
			main_text_shadow_color: 'rgba(255, 255, 255, 0.75)',
			main_hover_background_color: '#ddeeff',
			secondary_background_color: '#f9f9f9',
			secondary_font_color: '#333333',
			nav_background_color: '#f8f8f8',
			nav_border_color: '#e7e7e7',
			nav_font_color: '#3366cc',
			nav_selected_color: '#ffffff',
			nav_side_selected_color: '#337ab7',
			nav_side_selected_font_color: '#ffffff',
			nav_side_hover_background_color: '#eeeeee',
			nav_selected_font_color: '#000000',
			nav_selected_border_color: '#3366cc',
			nav_selected_box_shadow_color: '#e9e9e9',
			nav_hover_font_color: '#3366cc',
			nav_hover_border_color: '#3366cc',
			nav_hover_background_color: '#ffffff',
			input_background_color: '#ffffff',
			input_font_color: '#555555',
			input_border_color: '#cccccc',
			input_focus_border_color: '#66afe9',
			input_focus_box_shadow_color: '#66afe999',
			btn_background_color: '#f5f5f5',
			btn_secondary_background_color: '#ffffff',
			btn_third_background_color: '#e6e6e6',
			btn_font_color: '#333333',
			btn_border_color: '#cccccc #cccccc #b3b3b3',
			btn_hover_background_color: '#e6e6e6',
			link_font_color: '#337ab7',
			link_hover_font_color: '#23527c',	
		        syntax_keyword_color: '#006699',
			syntax_plain_color: '#000',
			syntax_functions_color: '#ff1493',
			syntax_string_color: '#0000ff',
			syntax_comments_color: '#008200',
			syntax_variable_color: '#aa7700',
			syntax_border_color: '#6ce26c',
			syntax_line_number_color: '#337ab7',
			syntax_hover_line_number_color: '#23527c',
			syntax_selected_line_background_color: '#e0e0e0',
			activity_background_color: '#36C',
			warning_background_color: '#f0ad4e',
			warning_font_color: '#ffffff',
			warning_border_color: '#eea236',
			warning_hover_background_color: '#ec971f',
			warning_hover_font_color: '#ffffff',
			warning_hover_border_color: '#d58512',
			primary_background_color: '#337ab7',
			primary_font_color: '#ffffff',
			primary_border_color: '#2e6da4',
			primary_hover_background_color: '#286090',
			primary_hover_font_color: '#ffffff',
			primary_hover_border_color: '#204d74',
			success_background_color: '#5cb85c',
			success_font_color: '#ffffff',
			success_border_color: '#4cae4c',
			success_hover_background_color: '#449d44',
			success_hover_font_color: '#ffffff',
			success_hover_border_color: '#398439',
			danger_background_color: '#d9534f',
			danger_font_color: '#d43f3a',
			danger_border_color: '#ffffff',
			danger_hover_background_color: '#c9302c',
			danger_hover_font_color: '#ffffff',
			danger_hover_border_color: '#ac2925',
			info_background_color: '#5bc0de',
			info_font_color: '#ffffff',
			info_border_color: '#46b8da',
			info_hover_background_color: '#31b0d5',
			info_hover_font_color: '#ffffff',
			info_hover_border_color: '#269abc',
			alert_success_background_color: '#d7f5dd',
			alert_success_font_color: '#333333',
			alert_success_border_color: '#d6e9c6',
			alert_success_link_color: '#337ab7',
			alert_warning_background_color: '#f5efd7',
			alert_warning_font_color: '#333333',
			alert_warning_border_color: '#faebcc',
			alert_warning_link_color: '#337ab7',
			alert_info_background_color: '#d7e1f5',
			alert_info_font_color: '#333333',
			alert_info_border_color: '#4083a3',
			alert_info_link_color: '#337ab7',
			alert_danger_background_color: '#f2dede',
			alert_danger_font_color: '#333333',
			alert_danger_border_color: '#ebccd1',
			alert_danger_link_color: '#337ab7'
		},
		custom: {},
		styles: {
			'body': {},
			'code, kbd, pre, samp': {},
			'.syntaxhighlighter a, .syntaxhighlighter div, .syntaxhighlighter code, .syntaxhighlighter table, .syntaxhighlighter table td, .syntaxhighlighter table tr, .syntaxhighlighter table tbody, .syntaxhighlighter table thead, .syntaxhighlighter table caption, .syntaxhighlighter textarea': {},
			'nav.navbar-default': {},
			'nav.navbar-default .navbar-nav > li > a': {},
			'nav.navbar .nav .active > a, .navbar .nav .active > a:hover': {},
			'nav.navbar .nav > li > a:hover': {},
			'.btn.search-btn': {},
			'.input-group input, .form-group input.form-control, .form-group select.form-control': {},
			'textarea.form-control': {},
			'.input-group input:focus, .form-group input.form-control:focus, .form-group select.form-control:focus, textarea.form-control:focus': {},
			'legend': {},
			'.content': {},
			'.nav-pills > li.active > a, .nav-pills > li.active > a:hover, .nav-pills > li.active > a:focus': {},
			'.nav-stacked > li > a': {},
			'.nav > li > a:hover, .nav > li > a:focus': {},
			'.author-pic > a > img': {},
			'.nav-list a, .nav-list .btn-link, .nav-list .nav-header': {},
			'.btn': {},
			'button.btn.btn-link': {},
			'button.btn.btn-link:hover, button.btn.btn-link:focus': {},
			'@media only screen and (-webkit-min-device-pixel-ratio: 2), not all, not all, not all, only screen and (min-resolution: 192dpi), only screen and (min-resolution: 2dppx)': {
				'.small-logo': {},
				'.big-logo': {},
			},
			'.small-logo': {},
			'body a': {},
			'body a:hover, body a:focus': {},
			'.table-striped > tbody > tr:nth-of-type(odd)': {},
			'body code': {},
			'body pre': {},
			'body .syntaxhighlighter .gutter .pod-line, body .syntaxhighlighter .pod-line:last-child': {},
			'body .syntaxhighlighter .container .pod-line': {},
			'body .syntaxhighlighter .container .pod-placeholder': {},
			'.pod-placeholder .btn-link': {},
			'.pod-placeholder .btn-link:hover': {},
			'.syntaxhighlighter .line .keyword': {},
			'.syntaxhighlighter .line .plain,.syntaxhighlighter .line .plain a': {},
			'.syntaxhighlighter .line .functions': {},
			'.syntaxhighlighter .line .string, .syntaxhighlighter .line .string a': {},
			'.syntaxhighlighter .comments, .syntaxhighlighter .comments a': {},
			'.syntaxhighlighter .variable': {},
			'body .syntaxhighlighter .pod-placeholder': {},
			'body .line a': {},
			'body .line a:hover': {},
			'.syntaxhighlighter .line.highlighted.alt1, .syntaxhighlighter .container .line.highlighted.alt2': {},
			'.syntaxhighlighter table .gutter .line.highlighted': {},
			'.syntaxhighlighter table .gutter .line': {},
			'.irc-chat:after': {},
			'input.form-control.tool-bar-form, select.form-control.tool-bar-form': {},	
			'input.form-control.tool-bar-form:focus, select.form-control.tool-bar-form:focus': {},
			'#index-container .index-border': {},
			'.content .release-documentation div.release-row:nth-of-type(even), .content .release-modules div.release-row:nth-of-type(even), .content .release-provides div.release-row:nth-of-type(even)': {},
			'div#last-changes': {},
			'.nav-list hr': {},
			'.content .page-header': {},
			'#feed_subscription .fa': {},
			'.notify-HANDOFF': {},
			'.notify-HANDOFF a': {},
			'.notify-NEEDHELP': {},
			'.notify-NEEDHELP a': {},
			'.notify-ADOPTME': {},
			'.notify-ADOPTME a': {},
			'.btn-primary': {},
			'.btn-success': {},
			'.btn-warning': {},
			'.btn-danger': {},
			'.btn-info': {},
			'.btn-primary:hover': {},
			'.btn-success:hover': {},
			'.btn-warning:hover': {},
			'.btn-danger:hover': {},
			'.btn-info:hover': {},
			'.author-results li': {},
			'h2.content-head span': {},
			'.panel.panel-default': {},
			'#metacpan-pod-renderer-pod': {},
			'.panel-default > .panel-heading': {},
			'.btn.btn-default': {},
			'.btn.btn-default:hover, .btn.btn-default:focus': {},
			'.btn.search-btn:hover, .btn.search-btn:focus': {},
			'.navbar .nav li.dropdown .dropdown-toggle .caret, .navbar .nav li.dropdown.open .caret': {},
			'.navbar .nav li.dropdown.open .dropdown-menu': {},
			'.dropdown-menu > li > a': {},
			'.navbar .nav li.dropdown.open a.dropdown-toggle': {},
			'.dropdown-menu > li > a:hover, .dropdown-menu > li > a:focus': {},
			'.navbar .nav > li > a > img': {},
			'ul.nav-list.slidepanel.sticky-panel-top.slidepanel-visible, ul.nav-list.slidepanel.slidepanel-visible': {},
			'button#right-panel-toggle': {},
			'.search-results .description': {},
			'.alert-danger': {},
			'.alert-danger a, .alert-danger a:hover': {},
			'.alert-warning': {},
			'.alert-warning a, .alert-warningr a:hover': {},
			'.alert-info': {},
			'.alert-info a, .alert-info a:hover': {},
			'.alert-success': {},
			'.alert-success a, .alert-success a:hover': {},
			'.autocomplete-suggestions': {},
			'.autocomplete-suggestions strong': {},
			'div.autocomplete-suggestions div:nth-child(2n+2)': {},
			'.autocomplete-suggestion:hover': {}
		},
		load: function () {
			var cb = function (author) {
				if (author.author) {
					author = author.author;
					window.localStorage.setItem('author', JSON.stringify(author));
				}
				if (author.theme) {
					var key;
					for (key in author.theme.color_scheme) {
						MetaTheme.customStyle(key, author.theme.color_scheme[key]);
					}
					MetaTheme.customStyle(
						'logo', 
						author.theme.dark_mode 
							? MetaTheme.dark.logo 
							: MetaTheme.light.logo
					);
					for (key in author.theme.fonts) {
						if (key.match(new RegExp('family$'))) {
							MetaTheme.customStyle(
								key,
								MetaTheme.fonts.find(
									function (n) { 
										if (n.name === author.theme.fonts[key]) { 
											return n 
										} 
									}
								)
							);	
						} else MetaTheme.customStyle(key, author.theme.fonts[key]);
					}
				} else {
					var key;
					for (key in MetaTheme.light) {
						MetaTheme.customStyle(key, MetaTheme.light[key]);
					}
					for (key in MetaTheme.fontDefaults) {
						MetaTheme.customStyle(key, MetaTheme.fontDefaults[key]);
					}
				}
				var activity = document.querySelector('.activity-graph img');
				if (activity) activity.src = activity.src + '&color=' + encodeURIComponent(MetaTheme.custom.activity_background_color);
				MetaTheme.buildCSS();
				MetaTheme.loaded = true;
			};


			var cachedCSS = window.localStorage.getItem('theme');
			if (cachedCSS) {
				var style = document.createElement('style');
				style.setAttribute('type', 'text/css');
				style.setAttribute('id', 'customStyles');
				style.innerText = cachedCSS;
				document.querySelector('head').appendChild(style);
			}	

			var author = window.localStorage.getItem('author');
			if (author) {
				author = JSON.parse(author);
				return cb(author);
			} else {
				this.getRequest(
					'/account/theme',
					{ },
					cb,
					function () { }
				);
			}
		},
		afterLoad: function (cb, params) {
			var interval;
			interval = setInterval(function () {
				if (MetaTheme.loaded) {
					if (typeof cb === 'string') MetaTheme[cb](params);
					else cb(params);
					clearInterval(interval);
				}
			}, 200);
		},
		encodedStr: function (url, str, obj) {
			if (typeof str !== 'string') { obj = str; str = ''; }
			let param;
			for (param in obj) {
				if (str) str += "&";
				str += encodeURIComponent(param) + "=" + encodeURIComponent(obj[param]);
			}
			return url + '?' + str;
		},
		getRequest: function (endpoint, params, cb, ecb) {
			var url = this.encodedStr(endpoint, params);
			var request = new XMLHttpRequest();
			request.onreadystatechange = function() {
				if (request.readyState === XMLHttpRequest.DONE) {
					if (request.status === 200) {
						var response = JSON.parse(request.response);
						cb(response);
					}
					else {
						ecb(request);
					}
				}
			};
			request.open('GET', url);
			request.setRequestHeader(
				'Content-Type',
				'application/json'
			);
			request.send();
		},
		switchMode: function (mode) {
			var key;
			for (key in this[mode]) {
				this.customStyle(key, this[mode][key]);
			}
			this.setColorPickers();
			this.buildCSS();
		},
		setFontFields: function () {
			var custom = this.custom;
			this.fontSizeSelectors.forEach(function (n) {
				var sel = 'input[name="' + n + '"]';
				var ele = document.querySelector(sel);
				ele.value = custom[n];
				ele.addEventListener('change', function (e) {
					MetaTheme.customStyle(this.name, this.value);
					MetaTheme.buildCSS();
				});
			});
			this.fontFamilySelectors.forEach(function (n) {
				var sel = document.querySelector('select[name="' + n + '"]');
				MetaTheme.fonts.forEach(function (f) {
					var selected = f.name === custom[n].name ? true : false;
					var opt = new Option(
						f.name, 
						f.name,
						selected,
						selected
					);
					sel.appendChild(opt);
				});
				sel.addEventListener('change', function (e) {
					var font = MetaTheme.fonts[this.selectedIndex];
					MetaTheme.customStyle(this.name, font);
					MetaTheme.buildCSS();
				});
			});
		},
		setColorPickers: function (mode) {
			var custom = this.custom;
			this.colorSelectors.forEach(function (n) {
				var sel = 'input[name="' + n + '"]';
				var ele = document.querySelector(sel);
				ele.value = custom[n];
				var picker;
				picker = jsColorPicker(
					sel,
					{
						customBG: '#222',
						init: function (elm, colors) {   
							elm.style.backgroundColor = elm.value;
							elm.style.color = colors.rgbaMixCustom.luminance > 0.22 ? '#222' : '#ddd'
						},
						actionCallback: function (val, e, o) {
							MetaTheme.customStyle(this.input.name, this.input.value);
							MetaTheme.buildCSS();
						}
					}
				);
			});
		},
		customStyle: function (key, value) {
			this.custom[key] = value;
		},
		setFontSheet: function (id) {
			var font = this.custom[id];
			var fscript = document.querySelector('head #' + id);
			if (fscript && (!font.url || font.url !== fscript.href)) 
				fscript.parentNode.removeChild(fscript);
			if (font.url) {
				fscript = document.createElement('link');
				fscript.id = id;
				fscript.setAttribute("rel", "stylesheet");
				fscript.setAttribute("type", "text/css");
				fscript.setAttribute("href", font.url);
				document.querySelector('head').appendChild(fscript);
			}
		},
		buildCSS: function () {
			this.setFontSheet('body_font_family');
			if ( this.custom.body_font_family.name !== this.custom.syntax_font_family.name ) 
				this.setFontSheet('syntax_font_family');
			this.styles.body = {
				'background-color': this.custom.main_background_color,
				'color': this.custom.main_font_color,
				'font-size': this.custom.body_font_size + 'px',
				'font-family': this.custom.body_font_family.name
			};
			var inputHeight = String(Number(this.custom.input_font_size) + 14) + 'px !important';
			if (this.custom.body_font_family.otf) {
			    this.styles.body.src = 'url(this.custom.body_font_family)';
			    inputHeight = String(Number(this.custom.input_font_size) + 26) + 'px !important';
			}
			this.styles['code, kbd, pre, samp'] = {
				'font-family': this.custom.syntax_font_family.name
			};
			this.styles['.syntaxhighlighter a, .syntaxhighlighter div, .syntaxhighlighter code, .syntaxhighlighter table, .syntaxhighlighter table td, .syntaxhighlighter table tr, .syntaxhighlighter table tbody, .syntaxhighlighter table thead, .syntaxhighlighter table caption, .syntaxhighlighter textarea'] = {
				'font-family': this.custom.syntax_font_family.name
			};
			this.styles['nav.navbar-default'] = {
				'background-color': this.custom.nav_background_color,
				'border-color': this.custom.nav_border_color,
			};
			this.styles['nav.navbar-default .navbar-nav > li > a']['color'] = this.custom.nav_font_color;
			this.styles['nav.navbar .nav .active > a, .navbar .nav .active > a:hover'] = {
				'background-color':  this.custom.nav_selected_color,
				'color': this.custom.nav_selected_font_color,
				'border-color': this.custom.nav_selected_border_color,
				'box-shadow': 'inset -1px 0px 0 ' + this.custom.nav_selected_box_shadow_color + ', inset 1px 0px 0 ' + this.custom.nav_selected_box_shadow_color,
				'-webkit-box-shadow': 'inset -1px 0px 0 ' + this.custom.nav_selected_box_shadow_color + ', inset 1px 0px 0 ' + this.custom.nav_selected_box_shadow_color
			};
			this.styles['nav.navbar .nav > li > a:hover'] = {
				'border-color': this.custom.nav_hover_border_color,
				'color': this.custom.nav_hover_font_color
			};
			this.styles['.input-group input, .form-group input.form-control, .form-group select.form-control'] = {
				'color': this.custom.input_font_color,
				'background': this.custom.input_background_color,
				'border-color': this.custom.input_border_color,
				'font-size': this.custom.input_font_size + 'px !important',
				'line-height': inputHeight,
				'height': inputHeight, 
			};
			this.styles['textarea.form-control'] = {
				'color': this.custom.input_font_color,
				'background': this.custom.input_background_color,
				'border-color': this.custom.input_border_color,
				'font-size': this.custom.input_font_size + 'px !important',
				'line-height': inputHeight,
			};
			this.styles['input.form-control.tool-bar-form, select.form-control.tool-bar-form'] = {
				'color': this.custom.input_font_color,		
				'background': this.custom.input_background_color,
				'border-color': this.custom.input_border_color,
				'font-size': this.custom.input_font_size + 'px',
				'line-height': inputHeight,
				'height': inputHeight
			};
			this.styles['input.form-control.tool-bar-form:focus, select.form-control.tool-bar-form:focus'] = {
				'border-color': this.custom.input_focus_border_color,
				'-webkit-box-shadow': 'inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 8px ' + this.custom.input_focus_box_shadow_color,
				'box-shadow': 'inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 8px ' + this.custom.input_focus_box_shadow_color
			};
			this.styles['.btn.search-btn'] = {
				'color': this.custom.btn_font_color,
				'border-color': this.custom.btn_border_color,
				'background-color': this.custom.btn_background_color,
				'background-image': 'linear-gradient(to bottom, ' + this.custom.btn_secondary_background_color + ' 0%, ' + this.custom.btn_third_background_color + ' 100%)',
				'text-shadow': '0 1px 1px ' + this.custom.main_text_shadow_color,
				'font-size': this.custom.input_font_size + 'px',
				'line-height': this.custom.input_font_size + 'px',
				'height': inputHeight,
			};
			this.styles['.btn.search-btn:hover, .btn.search-btn:focus'] = {
				'background': this.custom.btn_hover_background_color
			}
			this.styles['.input-group input:focus, .form-group input.form-control:focus, .form-group select.form-control:focus, textarea.form-control:focus'] = {
				'border-color': this.custom.input_focus_border_color,
				'-webkit-box-shadow': 'inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 8px ' + this.custom.input_focus_box_shadow_color,
				'box-shadow': 'inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 8px ' + this.custom.input_focus_box_shadow_color
			};
			this.styles['legend'] = {
				'color': this.custom.main_font_color,
				'border-color': this.custom.main_border_color
			};
			this.styles['.content'] = {
				'border-color': this.custom.main_border_color
			};
			this.styles['.nav-pills > li.active > a, .nav-pills > li.active > a:hover, .nav-pills > li.active > a:focus'] = {
				'background-color': this.custom.nav_side_selected_color,
				'color': this.custom.nav_side_selected_font_color
			};
			this.styles['.nav-stacked > li > a']['color'] = this.custom.nav_font_color;
			this.styles['.nav > li > a:hover, .nav > li > a:focus'] = {
				'background': this.custom.nav_side_hover_background_color,
				'color': this.custom.nav_hover_font_color
			};
			this.styles['.author-pic > a > img'] = {
				'-webkit-box-shadow': '2px 2px 5px ' + this.custom.main_box_shadow_color,
				'box-shadow': '2px 2px 5px ' + this.custom.main_box_shadow_color
			};
			this.styles['.nav-list a, .nav-list .btn-link, .nav-list .nav-header'] = {
				'text-shadow': '0 1px 0 ' + this.custom.main_text_shadow_color
			};
			this.styles['@media only screen and (-webkit-min-device-pixel-ratio: 2), not all, not all, not all, only screen and (min-resolution: 192dpi), only screen and (min-resolution: 2dppx)'] = {
				'.small-logo': {
					'background-image': 'url(' + this.custom.logo + ')'
				},
				'.big-logo': {
					'background-image': 'url(' + this.custom.logo + ')'
				}
			};
			this.styles['body a']['color'] = this.custom.link_font_color;
			this.styles['body a:hover, body a:focus']['color'] = this.custom.link_hover_font_color;
			this.styles['.table-striped > tbody > tr:nth-of-type(odd)']['background-color'] = this.custom.secondary_background_color;
			this.styles['body code'] = {
				'background-color': this.custom.secondary_background_color,
				'color': this.custom.secondary_font_color
			};
			this.styles['body pre'] = {
				'background-color': this.custom.secondary_background_color,
				'font-size': this.custom.body_font_size + 'px'
			};
			this.styles['body pre']['border-color'] = this.custom.main_border_color;
			this.styles['body .syntaxhighlighter .gutter .pod-line, body .syntaxhighlighter .pod-line:last-child'] = {
				'background-color': this.custom.main_background_color + ' !important',
				'border-color': this.custom.main_border_color + ' !important',
				'border-right': '3px solid ' + this.custom.syntax_border_color + ' !important'
			};
			this.styles['body .syntaxhighlighter .container .pod-line'] = {
				'background-color': this.custom.main_background_color + ' !important',
				'border-color': this.custom.main_border_color + ' !important',
				'background-color': this.custom.btn_background_color + ' !important',
				'border-color': this.custom.btn_border_color + ' !important'
			};
			this.styles['.pod-placeholder .btn-link']['color'] = this.custom.link_font_color + ' !important';
			this.styles['.pod-placeholder .btn-link:hover']['color'] = this.custom.link_hover_font_color + ' !important';
			this.styles['.syntaxhighlighter .line .keyword']['color'] = this.custom.syntax_keyword_color + ' !important';

			this.styles['.syntaxhighlighter .line .plain,.syntaxhighlighter .line .plain a']['color'] = this.custom.syntax_plain_color + ' !important';
			this.styles['.syntaxhighlighter .line .functions']['color'] = this.custom.syntax_functions_color + ' !important';
			this.styles['.syntaxhighlighter .line .string, .syntaxhighlighter .line .string a']['color'] = this.custom.syntax_string_color + ' !important';
			this.styles['.syntaxhighlighter .comments, .syntaxhighlighter .comments a']['color'] = this.custom.syntax_comments_color + ' !important';
			this.styles['.syntaxhighlighter .variable']['color'] = this.custom.syntax_variable_color + ' !important';
			this.styles['body .line a']['color'] = this.custom.syntax_line_number_color + ' !important';
			this.styles['body .line a:hover']['color'] = this.custom.syntax_hover_line_number_color + ' !important';
			this.styles['.syntaxhighlighter .line.highlighted.alt1, .syntaxhighlighter .container .line.highlighted.alt2']['background-color'] = this.custom.syntax_selected_line_background_color + ' !important';
			this.styles['.syntaxhighlighter table .gutter .line.highlighted']['background-color'] = this.custom.main_background_color + ' !important';
			this.styles['.syntaxhighlighter table .gutter .line']['border-color'] = this.custom.syntax_border_color + ' !important';
			this.styles['body .syntaxhighlighter .pod-placeholder']['background-color'] = this.custom.main_background_color + ' !important';
			this.styles['.irc-chat:after']['border-right'] = '12.39230485px solid ' + this.custom.main_background_color;
			this.styles['#index-container .index-border']['border-color'] = this.custom.main_border_color;
			this.styles['.content .release-documentation div.release-row:nth-of-type(even), .content .release-modules div.release-row:nth-of-type(even), .content .release-provides div.release-row:nth-of-type(even)']['background-color'] = this.custom.secondary_background_color;
			this.styles['div#last-changes'] = {
				'background-color': this.custom.secondary_background_color,
				'border-color': this.custom.main_border_color
			};
			this.styles['button.btn.btn-link']['color'] = this.custom.link_font_color + ' !important';
			this.styles['button.btn.btn-link:hover, button.btn.btn-link:focus']['color'] = this.custom.link_hover_font_color + ' !important';
			this.styles['.nav-list hr']['background-color'] = this.custom.main_border_color;
			this.styles['.content .page-header']['border-color'] = this.custom.main_border_color;
			this.styles['#feed_subscription .fa']['color'] = this.custom.main_font_color;
			this.styles['.notify-HANDOFF'] = {
				'background-color': this.custom.alert_info_background_color,
				'color': this.custom.alert_info_font_color
			};
			this.styles['.notify-HANDOFF a']['color'] = this.custom.alert_info_link_color;
			this.styles['.notify-NEEDHELP'] = {
				'background-color': this.custom.alert_success_background_color,
				'color': this.custom.alert_success_font_color
			};
			this.styles['.notify-NEEDHELP a']['color'] = this.custom.alert_success_link_color;
			this.styles['.notify-ADOPTME'] = {
				'background-color': this.custom.alert_warning_background_color,
				'color': this.custom.alert_warning_font_color
			}
			this.styles['.notify-ADOPTME a']['color'] = this.custom.alert_warning_link_color;
			this.styles['.btn-primary'] = {
				'background-color': this.custom.primary_background_color,
				'color': this.custom.primary_font_color,
				'border-color': this.custom.primary_border_color
			};
			this.styles['.btn-primary:hover'] = {
				'background-color': this.custom.primary_hover_background_color,
				'color': this.custom.primary_hover_font_color,
				'border-color': this.custom.primary_hover_border_color
			};
			this.styles['.btn-success'] = {
				'background-color': this.custom.success_background_color,
				'color': this.custom.success_font_color,
				'border-color': this.custom.success_border_color,
			};
			this.styles['.btn-success:hover'] = {
				'background-color': this.custom.success_hover_background_color,
				'color': this.custom.success_hover_font_color,
				'border-color': this.custom.success_hover_border_color
			};
			this.styles['.btn-warning'] = {
				'background-color': this.custom.warning_background_color,
				'color': this.custom.warning_font_color,
				'border-color': this.custom.warning_border_color
			};
			this.styles['.btn-warning:hover'] = {
				'background-color': this.custom.warning_hover_background_color,
				'color': this.custom.warning_hover_font_color,
				'border-color': this.custom.warning_hover_border_color
			};
			this.styles['.btn-danger'] = {
				'background-color': this.custom.danger_background_color,
				'color': this.custom.danger_font_color,
				'border-color': this.custom.danger_border_color
			};
			this.styles['.btn-danger:hover'] = {
				'background-color':  this.custom.danger_hover_background_color,
				'color': this.custom.danger_hover_font_color,
				'border-color': this.custom.danger_hover_border_color
			};
			this.styles['.btn-info'] = {
				'background-color': this.custom.info_background_color,
				'color': this.custom.info_font_color,
				'border-color': this.custom.info_border_color
			};
			this.styles['.btn-info:hover'] = {
				'background-color': this.custom.info_hover_background_color,
				'color': this.custom.info_hover_font_color,
				'border-color': this.custom.info_hover_border_color
			};
			this.styles['.author-results li'] = {
				'border-color': this.custom.main_border_color
			};
			this.styles['h2.content-head span'] = {
				'color': this.custom.danger_background_color + ' !important'
			};
			this.styles['.panel.panel-default'] = {
				'background-color': this.custom.main_background_color,
				'border-color': this.custom.main_border_color
			};
			this.styles['#metacpan-pod-renderer-pod'] = {
				'background-color':  this.custom.main_background_color,
				'border-color': this.custom.main_border_color,
				'color': this.custom.main_font_color
			};
			this.styles['.panel-default > .panel-heading'] = {
				'background-color': this.custom.secondary_background_color,
				'border-color': this.custom.main_border_color,
				'color': this.custom.secondary_font_color
			};
			this.styles['.btn.btn-default'] = {
				color: this.custom.btn_font_color,
				'border-color': this.custom.btn_border_color,
				'background-color': this.custom.btn_background_color,
				'background-image': 'linear-gradient(to bottom, ' + this.custom.btn_secondary_background_color + ' 0%, ' + this.custom.btn_third_background_color + ' 100%)',
				'text-shadow': '0 1px 1px ' + this.custom.main_text_shadow_color,
				'font-size': this.custom.input_font_size + 'px',
				'line-height': this.custom.input_font_size + 'px',
			};
			this.styles['.btn.btn-default:hover, .btn.btn-default:focus'] = {
				'background': this.custom.btn_hover_background_color
			};
			this.styles['.btn']['font-size'] = this.custom.body_font_size + 'px';
			this.styles['.navbar .nav li.dropdown .dropdown-toggle .caret, .navbar .nav li.dropdown.open .caret'] = {
				'border-top-color': this.custom.nav_font_color
			};
			this.styles['.navbar .nav li.dropdown.open .dropdown-menu'] = {
   	 			'background': this.custom.nav_selected_color, 
    				'border-color': this.custom.nav_border_color,
				'font-size': this.custom.body_font_size + 'px',
			};
			this.styles['.dropdown-menu > li > a'] = {
			    	'color': this.custom.nav_selected_font_color
			};
			this.styles['.navbar .nav li.dropdown.open a.dropdown-toggle'] = {
    				'background-color': this.custom.nav_selected_color,
				'color': this.custom.nav_selected_font_color,
				'border-color': this.custom.nav_border_color,
				'box-shadow':'inset -1px 0px 0 ' +  this.custom.nav_box_shadow_color 
					+ ', inset 1px 0px 0 ' +  this.custom.nav_box_shadow_color
			};
			this.styles['.dropdown-menu > li > a:hover, .dropdown-menu > li > a:focus'] = {
    				'color': this.custom.nav_selected_font_color,
    				'background-color': this.custom.nav_side_hover_background_color
			};
			this.styles['.navbar .nav > li > a > img'] = {
				'vertical-align': 'middle'
			};
			this.styles['.small-logo'] = {
				'background-size': '326px 92px',
				'background-image': 'url(' + this.custom.logo + ')'
			};
			this.styles['ul.nav-list.slidepanel.sticky-panel-top.slidepanel-visible, ul.nav-list.slidepanel.slidepanel-visible'] = {
				'background': this.custom.nav_background_color,
				'border-color': this.custom.nav_border_color
			};
			this.styles['button#right-panel-toggle'] = {
				'background': this.custom.main_background_color,
				'color': this.custom.main_font_color,
    				'border-color': this.custom.main_border_color
			};
			this.styles['.search-results .description'] = {
				'color': this.custom.main_second_font_color
			};
			this.styles['.alert-success'] = {
				'background-color': this.custom.alert_success_background_color,
				'color': this.custom.alert_success_font_color,
				'border-color': this.custom.alert_success_border_color
			};
			this.styles['.alert-success a, .alert-success a:hover'] = {
				'color': this.custom.alert_success_link_color,
			};
			this.styles['.alert-danger'] = {
				'background-color': this.custom.alert_danger_background_color,
				'color': this.custom.alert_danger_font_color,
				'border-color': this.custom.alert_danger_border_color
			};
			this.styles['.alert-danger a, .alert-danger a:hover'] = {
				'color': this.custom.alert_danger_link_color,
			};
			this.styles['.alert-warning'] = {
				'background-color': this.custom.alert_warning_background_color,
				'color': this.custom.alert_warning_font_color,
				'border-color': this.custom.alert_warning_border_color
			};
			this.styles['.alert-warning a, .alert-warning a:hover'] = {
				'color': this.custom.alert_warning_link_color,
			};

			this.styles['.alert-info'] = {
				'background-color': this.custom.alert_info_background_color,
				'color': this.custom.alert_info_font_color,
				'border-color': this.custom.alert_info_border_color
			};
			this.styles['.alert-info a, .alert-info a:hover'] = {
				'color': this.custom.alert_info_link_color,
			};
			this.styles['.autocomplete-suggestions'] = {
				'background-color': this.custom.main_background_color,
				'color': this.custom.main_secondary_font_color,
				'border': this.custom.main_border_color,
			};
			this.styles['.autocomplete-suggestions strong'] = {
				color: this.custom.main_font_color
			};
			this.styles['div.autocomplete-suggestions div:nth-child(2n+2)'] = {
				background: this.custom.secondary_background_color
			};
			this.styles['.autocomplete-suggestion:hover'] = {
				background: this.custom.main_hover_background_color + ' !important'
			};
			this.removeAttachedCSS();
			return this.attachCSS();
		},
		removeAttachedCSS: function () {
			var s = document.querySelector('head #customStyles');
			if (s) s.parentNode.removeChild(s);
		},
		attachCSS: function (styles, returnString) {
			if (!styles) styles = this.styles;
			var css = "", key;			
			for (key in styles) {
				css += key + " {";
				var props = styles[key], prop;
				for (prop in props) {
					if ( props[prop] instanceof Object ) {
						var h = {};
						h[prop] = props[prop];
						css += this.attachCSS(h, true);
					}
					else css += prop + ": " + props[prop] + ";";
				}
				css += "}";
			}
			if (returnString) return css;
			if (css) {
				var style = document.createElement('style');
				style.setAttribute('type', 'text/css');
				style.setAttribute('id', 'customStyles');
				style.innerText = css;
				document.querySelector('head').appendChild(style);
				window.localStorage.setItem('theme', css);
			}
		},
	};

	window.MetaTheme = new Theme();
})(window);
