export function getListManager(passwordList, tableBody, passwordRenderer, visibilitySetter) {
    function getIndex(row) {
        let index = 0;

        for (let child = row; child.previousSibling; child = child.previousSibling) {
            index += 1;
        }

        return index;
    }

    function getRow(domObject) {
        while (domObject.parentNode != tableBody) {
            domObject = domObject.parentNode;
        }

        return domObject;
    }

    function renderPassword(passwordObject) {
        const domObject = passwordRenderer(passwordObject);

        tableBody.appendChild(domObject);
    }

    tableBody.innerHTML = '';

    for (let password of passwordList) {
        renderPassword(password);
    }

    return {
        add: function(passwordObject) {
            passwordList.push(passwordObject);
            renderPassword(passwordObject);
        },
        get: function(domObject) {
            const row = getRow(domObject);
            const index = getIndex(row);

            return passwordList[index];
        },
        getAll: function() {
            return passwordList;
        },
        set: function(domObject, passwordObject, indexHint) {
            const row = getRow(domObject);
            const index = indexHint || getIndex(row);
            const newNode = passwordRenderer(passwordObject);

            passwordList[index] = passwordObject;
            tableBody.replaceChild(newNode, row);
        },
        remove: function(domObject) {
            const row = getRow(domObject);
            const index = getIndex(row);

            tableBody.removeChild(row);
            passwordList.splice(index, 1);
        },
        getIndex: function (domObject) {
            return getIndex(getRow(domObject));
        },
        filter: function(val) {
            const tokenList = val.toLowerCase().split(' ');
            const passwordCount = passwordList.length; // normally not necessary, but we do mutate passwordList
            let mismatchCount = 0;

            for(let i = 0; i < passwordCount; i++) {
                const index = i - mismatchCount;
                const passwordObject = passwordList[index];
                const searchable = (passwordObject.title + passwordObject.comment).toLowerCase();
                const isMatch = tokenList.every(token => -1 != searchable.indexOf(token));
                const row = tableBody.childNodes[index];

                visibilitySetter(row, isMatch);

                if ( ! isMatch) {
                    /* place row at bottom of list to preserve zebra colouring */
                    tableBody.insertBefore(row, null);
                    passwordList.push(passwordList.splice(index, 1)[0]);
                    mismatchCount += 1;
                }
            }
        }
    };
}
