"use strict";

function rewriteURL(link) {
    const url = link.dataset.urlTemplate;
    const input = link.parentNode.previousElementSibling;
    link.href = url.replace('%s', input.value);
    return true;
}

function removeDiv(div) {
    new Promise(resolve => {
        div.addEventListener("animationend", resolve);
        setTimeout(resolve, 400);
    }).then(() => div.parentNode.removeChild(div));
    div.classList.remove("slide-down");
    div.classList.add("slide-up");
}

function removeField(e) {
    e.preventDefault();
    removeDiv(this.closest('.field-container'));
}

function removeProfile(e) {
    e.preventDefault();
    removeDiv(this.closest('.profile-container'));
}

function addProfile(container, id, title, formatUrl) {
    const profileNode = document.importNode(document.querySelector('#profile-tmpl').content, true);
    profileNode.querySelector('.remove-profile').addEventListener('click', removeProfile);
    if (id) {
        profileNode.querySelector('div.form-group').classList.add('profile', 'profile-' + id);
        profileNode.querySelector('.profile-title').innerText = title;
        const profile_name = profileNode.querySelector('input[name="profile.name"]');
        profile_name.value = id;
        profile_name.type = 'hidden';

        const check_button = profileNode.querySelector('a.check-url');

        check_button.dataset.urlTemplate = formatUrl;

        check_button.addEventListener('click', () => {
            rewriteURL(check_button);
        });
    }
    container.append(profileNode);
}

function addField(container, id) {
    const fieldNode = document.importNode(document.querySelector('template#field-tmpl').content, true);
    fieldNode.querySelector('input').name = id;
    fieldNode.querySelector('.remove-field').addEventListener('click', removeField);
    container.append(fieldNode);
}

function validateJSON(input) {
    try {
        input.value && JSON.parse(input.value);
        input.classList.remove('invalid');
    }
    catch {
        input.classList.add('invalid');
    }
}

function fillLocation() {
    navigator.geolocation.getCurrentPosition((pos) => {
        document.querySelector('input[name="latitude"]').value = pos.coords.latitude;
        document.querySelector('input[name="longitude"]').value = pos.coords.longitude;
    }, function() {});
    return false;
}

const profileForm = document.querySelector('.profile-form');

if (profileForm) {
    for (const btn of profileForm.querySelectorAll(':scope .add-field')) {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            addField(this.closest('.field-container').parentNode, this.dataset.fieldType);
        });
    }

    for (const remove_field of profileForm.querySelectorAll(':scope .remove-field')) {
        remove_field.addEventListener('click', removeField);
    }

    profileForm.querySelector('.add-profile').addEventListener('change', function(e) {
        e.preventDefault();
        const option = this.selectedOptions[0];
        addProfile(
            document.querySelector('#metacpan_profiles'),
            this.value,
            option.dataset.title,
            option.dataset.urlFormat,
        );
        this.selectedIndex = 0;
    });

    for (const remove_profile of profileForm.querySelectorAll(':scope .remove-profile')) {
        remove_profile.addEventListener('click', removeProfile);
    }

    for (const check_url of profileForm.querySelectorAll(':scope .check-url')) {
        check_url.addEventListener('click', () => {
            rewriteURL(check_url);
        });
    }

    const extra = profileForm.querySelector('textarea[name="extra"]')
    extra.addEventListener('keyup', () => {
        validateJSON(extra);
    });
    validateJSON(extra);

    profileForm.querySelector('.fill-location').addEventListener('click', function(e) {
        e.preventDefault();
        fillLocation();
    });

    const donation_box = document.querySelector('#metacpan_donations');
    const donations = profileForm.querySelector('input[name="donations"]');
    donations.addEventListener('change', () => {
        donation_box.classList.remove("slide-out-hidden");

        if (donations.value) {
            donation_box.classList.add("slide-down");
            donation_box.classList.remove("slide-up");
        }
        else {
            donation_box.classList.remove("slide-down");
            donation_box.classList.add("slide-up");
        }
    });
}
