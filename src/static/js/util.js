export function uint8ToBase64(arr) {
    const CHUNK_SZ = 0x8000;
    let str = [];

    for (let i = 0; i < arr.length; i += CHUNK_SZ) {
        str.push(String.fromCharCode.apply(null, arr.subarray(i, i + CHUNK_SZ)));
    }

    return btoa(str.join(''));
}

export function base64ToUint8(str) {
    return new Uint8Array(window.atob(str).split('').map(c => c.charCodeAt(0)));
}