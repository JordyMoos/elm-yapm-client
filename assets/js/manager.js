import { config } from './config';
import { createCryptoManager, generateRandomPassword } from './crypto';
import { postAsync, getAsync } from './network';
import { getListManager } from './listManager';

// start download as early as possible
const downloadPromise = getAsync(config.apiEndPoint);

let outerLibraryPromise = downloadPromise
    .catch(() => new Promise((resolve, reject) => {
        const cachedLibrary = window.localStorage.getItem(config.localStorageKey);

        if (cachedLibrary) {
            resolve(cachedLibrary);
        }
        else {
            reject('Couldn\'t download library and there was no cached version');
        }
    }))
    .then(JSON.parse);

function selectText() {
    if (document.selection) {
        let range = document.body.createTextRange();
        range.moveToElementText(this);
        range.select();
    } else if (window.getSelection) {
        let range = document.createRange();
        range.selectNode(this);
        window.getSelection().addRange(range);
    }
}

function addObscuredCell(row, text) {
    let node = document.createElement('td');
    let span = document.createElement('div');
    span.classList.add('obscured');
    span.innerHTML = text;
    span.addEventListener('click', selectText);
    node.appendChild(span);
    row.appendChild(node);
}

function addLinkCell(row, url, text) {
    let node = document.createElement('td');
    let anchor = document.createElement('a');
    anchor.href = url;
    anchor.innerHTML = text;
    anchor.target = '_blank';
    node.appendChild(anchor);
    row.appendChild(node);
}

function addComment(row, text) {
    let node = document.createElement('td');
    let table = document.createElement('table');
    let tableRow = document.createElement('tr');
    let cell = document.createElement('td');
    table.classList.add('comment');
    cell.innerHTML = text;
    tableRow.appendChild(cell);
    table.appendChild(tableRow);
    node.appendChild(table);
    row.appendChild(node);
}

function setVisibility(row, isVisible) {
    if (isVisible) {
        row.classList.remove('hidden');
    }
    else {
        row.classList.add('hidden');
    }
}

/**
 * @param url     string
 * @param library object
 * @param hash    string
 * @param newHash string
 * @returns Promise
 */
function postLibraryAsync(url, library, hash, newHash) {
    const encodedLibrary = encodeURIComponent(JSON.stringify(library));
    const params = `pwhash=${hash}&newlib=${encodedLibrary}&newhash=${newHash}`;

    return postAsync(url, params);
}

/* filter shortcut: ctrl+e */
function isFilterShortCut(event) {
    return event.ctrlKey && event.keyCode === 69;
}

function isEscapeKey(event) {
    return event.keyCode === 27;
}

window.onload = function() {
    let listManager = null;
    let cryptoManager = null;
    let idleTime = 0;

    let $masterKeyInput = document.getElementById('encryptionKey');
    let $filterInput = document.getElementById('filter');
    let $titleInput = document.getElementById('title');
    let $urlInput = document.getElementById('URL');
    let $userNameInput = document.getElementById('username');
    let $passwordInput = document.getElementById('pass');
    let $passwordRepeatInput = document.getElementById('passRepeat');
    let $commentInput = document.getElementById('comment');
    let $newMasterKeyInput = document.getElementById('key');
    let $newMasterKeyRepeatInput = document.getElementById('keyRepeat');

    let $randomPasswordButton = document.getElementById('randPass');
    let $saveButton = document.getElementById('save');
    let $saveMasterKeyButton = document.getElementById('saveKey');
    let $modalCloseButtonOne = document.getElementById('modalClose1');
    let $modalCloseButtonTwo = document.getElementById('modalClose2');
    let $newPasswordButtonList = document.getElementsByClassName('newPassword');
    let $newMasterKeyButtonList = document.getElementsByClassName('newMasterKey');

    let $decryptForm = document.getElementById('decrypt');
    let $tableBody = document.getElementById('overview').lastChild;
    let $editModal = document.getElementById('editModal');
    let $editModalHeader = document.getElementById('modalHeader');
    let $masterKeyModal = document.getElementById('masterkeyModal');
    let $authorizedSection = document.getElementById('authorized');
    let $unauthorizedSection = document.getElementById('unauthorized');

    $masterKeyInput.focus();
    setInterval(incrementIdleTime, 1000);

    $decryptForm.addEventListener('submit', decryptPage, false);
    $saveButton.addEventListener('click', saveChanges);
    $randomPasswordButton.addEventListener('click', setRandomPassword);
    $editModal.addEventListener('click', closeDialog);
    $masterKeyModal.addEventListener('click', closeDialog);
    $modalCloseButtonOne.addEventListener('click', closeDialog);
    $modalCloseButtonTwo.addEventListener('click', closeDialog);

    $filterInput.addEventListener('keyup', filterList);
    document.addEventListener('touchstart', resetIdleTime, false);
    document.addEventListener('touchmove', resetIdleTime, false);
    document.addEventListener('touchend', resetIdleTime, false);
    document.addEventListener('keydown', checkKeyDown, false);
    document.onmousemove = resetIdleTime;

    // FIXME: maybe we should just set a css class somewhere and hide these properties in css
    downloadPromise
        .then(() => {
            for(let button of $newPasswordButtonList) {
                button.addEventListener('click', newPW);
            }

            for(let button of $newMasterKeyButtonList) {
                button.addEventListener('click', newMasterPW);
            }

            $saveMasterKeyButton.addEventListener('click', saveMasterKey);
        })
        .catch(() => {
            for(let button of $newPasswordButtonList) {
                button.parentNode.removeChild(button);
            }

            for(let button of $newMasterKeyButtonList) {
                button.parentNode.removeChild(button);
            }
        });

    function decryptPage(evt) {
        evt.preventDefault();

        const password = $masterKeyInput.value;
        $masterKeyInput.value = '';

        const listPromise = outerLibraryPromise
            .then(library => createCryptoManager(password, library))
            .then(newManager => {
                return cryptoManager = newManager;
            })
            .then(newManager => newManager.getPasswordList());

        Promise.all([outerLibraryPromise, listPromise])
            .then(params => window.localStorage.setItem(config.localStorageKey, JSON.stringify(params[0])));

        const onlinePromise = downloadPromise.then(() => true).catch(() => false);

        Promise.all([listPromise, onlinePromise])
            .then(params => getListManager(params[0], $tableBody, createRenderer(params[1]), setVisibility))
            .then(newManager => {
                listManager = newManager;

                $authorizedSection.classList.remove('hidden');
                $unauthorizedSection.classList.add('hidden');
                $filterInput.focus();
            })
            .catch(error => window.alert(`Something went wrong: ${error}`));

        return false;
    }

    function resetIdleTime() {
        idleTime = 0;
    }

    function incrementIdleTime() {
        if (++idleTime > config.maxIdleTime) {
            logout();
        }
    }

    function checkKeyDown(evt) {
        resetIdleTime();

        if (isFilterShortCut(evt)) {
            evt.preventDefault();
            $filterInput.focus();
        }
        else if (isEscapeKey(evt)) {
            closeDialog();
        }
    }

    function closeDialog(event) {
        if (event && event.target != this) {
            return;
        }

        $editModal.classList.add('hidden');
        $masterKeyModal.classList.add('hidden');
    }

    function editDialog(domObject) {
        const isNew = typeof domObject == 'undefined';
        const passwordObject = isNew ? null : listManager.get(domObject);
        const index = isNew ? -1 : listManager.getIndex(domObject);

        $editModal.classList.remove('hidden');
        $editModal.setAttribute('data-index', index);
        $editModalHeader.innerHTML = isNew ? 'New password' : 'Edit password';
        $titleInput.value          = isNew ? '' : passwordObject.title;
        $urlInput.value            = isNew ? '' : passwordObject.url;
        $userNameInput.value       = isNew ? '' : passwordObject.username;
        $passwordInput.value       = isNew ? '' : passwordObject.password;
        $passwordRepeatInput.value = isNew ? '' : passwordObject.password;
        $commentInput.value        = isNew ? '' : passwordObject.comment;

        $titleInput.focus();
    }

    function saveChanges(evt) {
        evt.preventDefault();

        if ($passwordInput.value !== $passwordRepeatInput.value) {
            return window.alert('Passwords do not match!');
        }

        const index = parseInt($editModal.getAttribute('data-index'));
        let passwordObject = {
            title: $titleInput.value,
            url: $urlInput.value,
            username: $userNameInput.value,
            password: $passwordInput.value,
            comment: $commentInput.value
        };

        if (index === -1) {
            listManager.add(passwordObject);
            listManager.filter($filterInput.value);
        }
        else {
            let domObject = $tableBody.firstChild;
            for (let i = 0; i < index; i++) {
                domObject = domObject.nextSibling;
            }

            listManager.set(domObject, passwordObject, index);
        }

        sendUpdate().catch(msg => window.alert('Failed updating library: ' + msg));
        closeDialog();
    }

    function saveMasterKey(evt) {
        evt.preventDefault();

        if ( ! window.confirm('Are you sure you want to change the master key?')) {
            return closeDialog();
        }

        const newKey = $newMasterKeyInput.value;
        const newKeyRepeat = $newMasterKeyRepeatInput.value;

        if (newKey !== newKeyRepeat) {
            return window.alert('New keys do not match!');
        }

        sendUpdate(newKey)
            .then(closeDialog)
            .catch(msg => window.alert('Failed updating password: ' + msg));
    }

    function deletePassword(evt) {
        evt.preventDefault();

        if ( ! window.confirm("Are you totally sure you want to delete this password?")) {
            return;
        }

        listManager.remove(this);
        sendUpdate()
            .catch(msg => window.alert('Failed deleting password: ' + msg));
    }

    function toggleVisibility(evt) {
        let row = this.parentNode.parentNode;
        this.innerHTML = row.classList.contains('exposed') ? '<i class="icon-eye"></i>' : '<i class="icon-eye-off"></i>';

        row.classList.toggle('exposed');
        evt.preventDefault();
    }

    function copyPassword(evt) {
        var passwordField = this.parentNode.parentNode.childNodes[2];
        var range = document.createRange();  
        range.selectNode(passwordField);
        window.getSelection().addRange(range);

        try {  
            var successful = document.execCommand('copy');

            let alertBox = document.createElement('alert');
            alertBox.innerHTML = "<strong>Copied!</strong> The password is now in your clipboard and ready for use.";
            $authorizedSection.appendChild(alertBox);
            window.setTimeout(() => $authorizedSection.removeChild(alertBox), 10000);
        } catch(err) {  
            window.alert('Oops, unable to copy');  
        }

        window.getSelection().removeAllRanges();
    }

    function logout() {
        listManager = null;
        cryptoManager = null;

        $tableBody.innerHTML = '';
        $masterKeyInput.focus();
        $authorizedSection.classList.add('hidden');
        $unauthorizedSection.classList.remove('hidden');
        $userNameInput.value = '';
        $passwordInput.value = '';
        $passwordRepeatInput.value = '';
    }

    function sendUpdate(newKey) {
        let oldHashPromise = cryptoManager.getHash();
        let libraryPromise = cryptoManager.encryptPasswordList(listManager.getAll(), newKey);
        let newHashPromise = libraryPromise.then(cryptoManager.getHash);

        return Promise.all([oldHashPromise, libraryPromise, newHashPromise])
            .then(params => {
                let [oldHash, signedLib, newHash] = params;
                outerLibraryPromise = outerLibraryPromise.then(() => signedLib);
                window.localStorage.setItem(config.localStorageKey, JSON.stringify(signedLib));

                return postLibraryAsync(config.apiEndPoint, signedLib, oldHash, newHash);
            });
    }

    function setRandomPassword(evt) {
        const newPassword = generateRandomPassword();

        $passwordInput.value = newPassword;
        $passwordRepeatInput.value = newPassword;

        evt.preventDefault();
    }

    function filterList() {
        listManager.filter(this.value);
    }

    function newPW(evt) {
        evt.preventDefault();
        editDialog();
    }

    function newMasterPW(evt) {
        evt.preventDefault();
        $masterKeyModal.classList.remove('hidden');
        $newMasterKeyInput.focus();
    }

    function addLinks(row, isOnline) {
        let node = document.createElement('td');
        let link = document.createElement('a');
        link.href = '#';
        link.classList.add('copyPassword');
        link.innerHTML = '<i class="icon-docs"></i>';
        link.addEventListener('click', copyPassword);
        node.appendChild(link);

        link = document.createElement('a');
        link.href = '#';
        link.classList.add('toggleVisibility');
        link.innerHTML = '<i class="icon-eye"></i>';
        link.addEventListener('click', toggleVisibility);
        node.appendChild(link);

        if (isOnline) {
            link = document.createElement('a');
            link.href = '#';
            link.classList.add('editPassword');
            link.innerHTML = '<i class="icon-edit"></i>';
            link.addEventListener('click', () => editDialog(link));
            node.appendChild(link);

            link = document.createElement('a');
            link.href = '#';
            link.classList.add('deletePassword');
            link.innerHTML = '<i class="icon-trash"></i>';
            link.addEventListener('click', deletePassword);
            node.appendChild(link);
        }

        row.appendChild(node);
    }

    function createRenderer(isOnline) {
        return function(passwordObject) {
            let row = document.createElement('tr');
            addLinkCell(row, passwordObject.url, passwordObject.title);
            addObscuredCell(row, passwordObject.username);
            addObscuredCell(row, passwordObject.password);
            addComment(row, passwordObject.comment);
            addLinks(row, isOnline);

            return row;
        };
    }
};
