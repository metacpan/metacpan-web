window.addEventListener('DOMContentLoaded', function() {

if (!document.querySelector('.profile-form')) return;

"use strict";

function rewriteURL(link) {
    const url = link.dataset.urlTemplate;
    const input = link.parentNode.previousElementSibling;
    link.href = url.replace('%s', input.value);
    return true;
}

for (const check_url of document.querySelectorAll('.account-settings .check-url')) {
    check_url.addEventListener('click', function(e) {
        return rewriteURL(this);
    });
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
for (const remove_field of document.querySelectorAll('.account-settings .remove-field')) {
    remove_field.addEventListener('click', removeField);
}

function removeProfile(e) {
    e.preventDefault();
    removeDiv(this.closest('.profile-container'));
}

for (const remove_profile of document.querySelectorAll('.account-settings .remove-profile')) {
    remove_profile.addEventListener('click', removeProfile);
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
        profileNode.querySelector('a.check-url').dataset.urlTemplate(formatUrl);

        for (const check_url of profileNode.querySelectorAll(':scope .check-url')) {
            check_url.addEventListener('click', function(e) {
                return rewriteURL(this);
            });
        }
    }
    container.append(profileNode);
}

document.querySelector('.account-settings .add-profile').addEventListener('change', function(e) {
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

function addField(container, id) {
    const fieldNode = document.importNode(document.querySelector('template#field-tmpl').content, true);
    fieldNode.querySelector('input').name = id;
    fieldNode.querySelector('.remove-field').addEventListener('click', removeField);
    container.append(fieldNode);
}

for (const btn of document.querySelectorAll('.account-settings button.add-field')) {
    btn.addEventListener('click', function (e) {
        e.preventDefault();
        addField(this.closest('.field-container').parentNode, this.dataset.fieldType);
    });
}


function validateJSON(input) {
    try {
        input.value && JSON.parse(input.value);
        input.classList.remove('invalid');
    } catch(err) {
        input.classList.add('invalid');
    }
}

const extra = document.querySelector('.account-settings textarea[name="extra"]')
extra.addEventListener('keyup', function (e) {
    validateJSON(this);
});
validateJSON(extra);

function fillLocation() {
    navigator.geolocation.getCurrentPosition((pos) => {
        document.querySelector('input[name="latitude"]').value = pos.coords.latitude;
        document.querySelector('input[name="longitude"]').value = pos.coords.longitude;
    }, function(){
    });
    return false;
}

document.querySelector('.account-settings button.fill-location').addEventListener('click', function (e) {
    e.preventDefault();
    fillLocation();
});

const donation_box = document.querySelector('#metacpan_donations');
document.querySelector('.profile-form input[name="donations"]').addEventListener('change', (e) => {
    if (donation_box.classList.contains("slide-out-hidden")) {
        donation_box.classList.toggle("slide-out-hidden");
    }
    else {
        donation_box.classList.toggle("slide-up");
    }
    donation_box.classList.toggle("slide-down");
});

});
