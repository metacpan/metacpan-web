import jQuery from 'jquery';
import {
    formatTOC,
    createAnchors
}
from './document-ui.mjs';

const pod2html_form = jQuery('#metacpan-pod-renderer-form');
const pod2html_text = jQuery('[name="pod"]', pod2html_form);
const pod2html_update = function(pod) {
    if (!pod) {
        pod = pod2html_text.get(0).value;
    }
    const submit = pod2html_form.find('input[type="submit"]');
    submit.attr("disabled", "disabled");
    const rendered = jQuery('#metacpan-pod-renderer-output');
    const loading = jQuery('#metacpan-pod-renderer-loading');
    const error = jQuery('#metacpan-pod-renderer-error');
    rendered.hide();
    rendered.html('');
    loading.show();
    error.hide();
    document.title = "Pod Renderer - metacpan.org";
    jQuery.ajax({
        url: '/pod2html',
        method: 'POST',
        data: {
            pod: pod
        },
        headers: {
            Accept: "application/json"
        },
        success: function(data) {
            const title = data.pod_title;
            document.title = "Pod Renderer - " + title + " - metacpan.org";
            rendered.html(
                '<nav class="toc"><div class="toc-header"><strong>Contents</strong></div>' +
                data.pod_index +
                '</nav>' +
                data.pod_html
            );
            var toc = jQuery("nav", rendered);
            if (toc.length) {
                formatTOC(toc[0]);
            }
            createAnchors(rendered);
            loading.hide();
            error.hide();
            rendered.show();
            submit.removeAttr("disabled");
        },
        error: function(data) {
            rendered.hide();
            loading.hide();
            error.html('Error rendering POD' +
                (data && data.length ? ' - ' + data : ''));
            error.show();
            submit.removeAttr("disabled");
        }
    });
};
if (window.FileReader) {
    jQuery('input[type="file"]', pod2html_form).on('change', function() {
        const files = this.files;
        for (var i = 0; i < files.length; i++) {
            const file = files[i];
            const reader = new FileReader();
            reader.onload = function(e) {
                pod2html_text.get(0).value = e.target.result;
                pod2html_update(e.target.result);
            };
            reader.readAsText(file);
        }
        this.value = null;
    });
}
pod2html_form.on('submit', function(e) {
    e.preventDefault();
    e.stopPropagation();
    pod2html_update();
});

const renderer = jQuery(".metacpan-pod-renderer")

let dragTimer;
renderer.on("dragover", function(event) {
    event.preventDefault();
    if (dragTimer) {
        window.clearTimeout(dragTimer);
    }
    dragTimer = window.setTimeout(function() {
        renderer.removeClass("dragging");
        window.clearTimeout(dragTimer);
        dragTimer = null;
    }, 500);
});

jQuery(document).on("dragenter", function() {
    renderer.addClass("dragging");
});

renderer.on("drop", function(event) {
    event.preventDefault();
    event.stopPropagation();
    renderer.removeClass("dragging");
    if (dragTimer) {
        window.clearTimeout(dragTimer);
        dragTimer = null;
    }
    const reader = new FileReader();
    reader.onload = function(e) {
        pod2html_text.get(0).value = e.target.result;
        pod2html_update(e.target.result);
    };
    reader.readAsText(event.originalEvent.dataTransfer.files[0]);
});
