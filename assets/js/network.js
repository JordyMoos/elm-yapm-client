export function getAsync(url) {
    return ajaxAsync(url, 'GET', []);
}

export function postAsync(url, params) {
    return ajaxAsync(
        url,
        'POST',
        [
            ['Content-type', 'application/x-www-form-urlencoded']
        ],
        params
    );
}

function ajaxAsync(url, method, requestHeaders, params) {
    return new Promise(function(resolve, reject) {
        let request = new XMLHttpRequest();
        request.open(method, url, true);

        request.onreadystatechange = function() {
            if(this.readyState === 4) {
                if(this.status !== 200) {
                    reject(request.responseText);
                }
                else {
                    resolve(request.responseText);
                }
            }
        };

        for (let pair of requestHeaders) {
            request.setRequestHeader(pair[0], pair[1]);
        }

        request.send(params);
    });
}
