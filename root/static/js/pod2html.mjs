import {
    formatTOC,
    createAnchors,
}
    from './document-ui.mjs';

const pod2htmlForm = document.querySelector('#metacpan-pod-renderer-form');
if (pod2htmlForm) {
    const textInput = pod2htmlForm.querySelector('[name="pod"]');
    const submit = pod2htmlForm.querySelector('input[type="submit"]');
    const renderer = document.querySelector('.metacpan-pod-renderer');
    const rendered = document.querySelector('#metacpan-pod-renderer-output');
    const loading = document.querySelector('#metacpan-pod-renderer-loading');
    const error = document.querySelector('#metacpan-pod-renderer-error');
    const template = document.querySelector('#metacpan-pod-renderer-content');

    const parseHTML = (html) => {
        const template = document.createElement('template');
        template.innerHTML = html;
        return template.content;
    };
    const updateHTML = async (pod) => {
        if (!pod) {
            pod = textInput.value;
        }
        submit.disabled = true;
        document.title = 'Pod Renderer - metacpan.org';

        rendered.style.display = 'none';
        rendered.replaceChildren();
        loading.style.display = 'block';
        error.style.display = 'none';

        try {
            const form = new FormData();
            form.set('pod', pod);

            const response = await fetch('/pod2html', {
                method:  'POST',
                headers: {
                    Accept: 'application/json',
                },
                body: form,
            });

            if (!response.ok) {
                throw new Error(await response.text());
            }

            const data = await response.json();

            document.title = 'Pod Renderer - ' + data.pod_title + ' - metacpan.org';

            const body = template.content.cloneNode(true);
            body.querySelector('.toc-body').replaceWith(parseHTML(data.pod_index));
            body.querySelector('.pod-body').replaceWith(parseHTML(data.pod_html));

            rendered.replaceChildren(body);

            formatTOC(rendered.querySelector('nav'));
            createAnchors(rendered);

            loading.style.display = 'none';
            error.style.display = 'none';
            rendered.style.display = 'block';

            submit.disabled = false;
        }
        catch (err) {
            rendered.style.display = 'none';
            loading.style.display = 'none';

            error.replaceChildren();
            error.append('Error rendering POD - ' + err.message);
            error.style.display = 'block';
            submit.disabled = false;
        }
    };

    pod2htmlForm.addEventListener('submit', (ev) => {
        ev.preventDefault();
        ev.stopPropagation();
        updateHTML();
    });

    const readFile = (file) => {
        const reader = new FileReader();
        reader.addEventListener('load', () => {
            textInput.value = reader.result;
            updateHTML(reader.result);
        });
        reader.readAsText(file);
    };

    const fileInput = pod2htmlForm.querySelector('input[type="file"]');
    fileInput.addEventListener('change', () => {
        const file = fileInput.files[0];
        if (!file) {
            return;
        }
        readFile(file);
        fileInput.value = null;
    });

    let dragTimer;
    renderer.addEventListener('dragover', (ev) => {
        ev.preventDefault();
        if (dragTimer) {
            window.clearTimeout(dragTimer);
        }
        dragTimer = window.setTimeout(() => {
            renderer.classList.remove('dragging');
            window.clearTimeout(dragTimer);
            dragTimer = null;
        }, 500);
    });

    document.addEventListener('dragenter', function () {
        renderer.classList.add('dragging');
    });

    renderer.addEventListener('drop', (ev) => {
        const data = ev.dataTransfer;
        if (data && data.files && data.files.length) {
            const file = data.files[0];

            ev.preventDefault();
            ev.stopPropagation();
            renderer.classList.remove('dragging');
            if (dragTimer) {
                window.clearTimeout(dragTimer);
                dragTimer = null;
            }

            readFile(file);
        }
    });
}
