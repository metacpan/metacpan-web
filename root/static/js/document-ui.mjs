import storage from './storage.js';

export const createAnchors = (topList) => {
    const it = typeof(topList)[Symbol.iterator] === 'function' ? topList : [topList];
    for (const top of it) {
        for (const heading of top.querySelectorAll(':scope h1,h2,h3,h4,h5,h6,dt')) {
            const id = heading.id;
            if (!id) {
                continue;
            }

            const link = document.createElement('a');
            link.href = '#' + id;
            link.classList.add('anchor');

            const icon = document.createElement('span');
            icon.classList.add('fa', 'fa-bookmark', 'black');
            link.append(icon);

            heading.prepend(link);
        }
    }
}

export const formatTOC = (toc) => {
    if (storage.getItem('hideTOC') == 1) {
        toc.classList.add("hide-toc");
    }

    const toc_header = toc.querySelector('.toc-header');
    const toc_body = toc.querySelector('ul');

    toc_header.insertAdjacentHTML('beforeend',
        ' [ <button class="btn-link toggle-toc"><span class="toggle-show">show</span><span class="toggle-hide">hide</span></button> ]'
    );
    toc_header.querySelector('.toggle-toc').addEventListener('click', e => {
        e.preventDefault();
        const currentVisible = !toc.classList.contains('hide-toc');
        storage.setItem('hideTOC', currentVisible ? 1 : 0);

        const fullHeight = toc_body.scrollHeight;

        if (currentVisible) {
            const trans = toc_body.style.transition;
            toc_body.style.transition = '';

            requestAnimationFrame(() => {
                toc_body.style.height = fullHeight + 'px';
                toc_body.style.transition = trans;
                toc.classList.toggle('hide-toc');

                requestAnimationFrame(() => {
                    toc_body.style.height = null;
                });
            });
        }
        else {
            const finish = () => {
                toc_body.removeEventListener('transitionend', finish);
                toc_body.style.height = null;
            };

            toc_body.addEventListener('transitionend', finish);
            toc_body.style.height = fullHeight + 'px';
            toc.classList.toggle('hide-toc');
        }
    });
};
