const realCrypto = (window.crypto || window.msCrypto).subtle;

/**
 * @param password string
 * @returns Promise
 */
export function getSha1(password) {
    return realCrypto.digest(
        {
            name: "SHA-1"
        },
        stringToArrayBuffer(password)
    )
    .then(arrayBufferToHexString);
}

/**
 * @param password string
 * @returns Promise
 */
export function getAesKey(password) {
    return realCrypto.importKey(
        "raw",
        stringToArrayBuffer(password),
        {
            "name": "PBKDF2"
        },
        false,
        ["deriveKey"]
    )
    .then(baseKey =>
        realCrypto.deriveKey(
            {
                "name": "PBKDF2",
                "salt": new Uint8Array(16),
                "iterations": 4096,
                "hash": {
                    name: "SHA-1"
                }
            },
            baseKey,
            {
                "name": "AES-CBC",
                "length": 256
            },
            false,
            ["encrypt", "decrypt"]
        )
    );
}

/**
 * @param password string
 * @returns Promise
 */
export function getHmacKey(password) {
    return realCrypto.importKey(
        "raw",
        stringToArrayBuffer(password),
        {
            name: "HMAC",
            hash: {
                name: "SHA-256"
            }
        },
        false,
        ["sign", "verify"]
    );
}

export function encodeIvFromNumber(num) {
    // iv is 16 bytes long
    let iv = new Uint8Array(16);

    // support num up to 8 bytes long
    for(let i = 0; i < 8; i++) {
        iv[i] = num & 255;

        num = num >>> 8;
    }

    return iv;
}

function stringToArrayBuffer(string) {
    let encoder = new window.TextEncoder("utf-8");

    return encoder.encode(string);
}

function bufferToByteArray(buffer) {
    return new Uint8Array(buffer);
}

function arrayBufferToHexString(arrayBuffer) {
    let byteArray = new Uint8Array(arrayBuffer);
    let hexString = "";
    let nextHexByte;

    for (let i = 0; i < byteArray.byteLength; i++) {
        nextHexByte = byteArray[i].toString(16);
        if (nextHexByte.length < 2) {
            nextHexByte = "0" + nextHexByte;
        }
        hexString += nextHexByte;
    }

    return hexString;
}

/**
 * @param key       AesKey
 * @param version   int
 * @param byteArray Uint8Array
 * @returns Uint8Array
 */
export function decrypt(key, version, byteArray) {
    return realCrypto.decrypt(
        {
            name: "AES-CBC",
            iv: encodeIvFromNumber(version)
        },
        key,
        byteArray
    )
    .then(bufferToByteArray);
}

/**
 * @param key     KeyObject
 * @param  arr    Uint8Array
 * @param version int
 * @returns Promise
 */
export function encryptUint8Array(key, arr, version) {
    return realCrypto.encrypt(
        {
            name: "AES-CBC",
            iv: encodeIvFromNumber(version)
        },
        key,
        arr
    )
    .then(bufferToByteArray);
}

/**
 * @param key HmacKey
 * @param str string
 * @returns Promise containing string (base64 encoding)
 */
export function getHmac(key, str) {
    return realCrypto.sign(
        {
            name: "HMAC"
        },
        key,
        stringToArrayBuffer(str)
    )
    .then(bufferToByteArray);
}

/**
 * @param key  HmacKey
 * @param str  string
 * @param hmac Uint8Array
 * @returns Promise
 */
export function verifyHmac(key, str, hmac) {
    return realCrypto.verify(
        {
            name: "HMAC"
        },
        key,
        hmac,
        stringToArrayBuffer(str)
    );
}
