import { compressToUint8Array, decompressFromUint8Array } from './lzstring';
import { getHmacKey, getAesKey, getSha1, decrypt, verifyHmac, encryptUint8Array, getHmac } from './crypto-primitives'
import { uint8ToBase64, base64ToUint8 } from './util';

const apiVersion = 3;

export function createCryptoManager(password, library) {
    let hmacKeyPromise = getHmacKey(password);
    let aesKeyPromise  = getAesKey(password);
    let hashPromise    = getSha1(password);

    let libraryPromise = hmacKeyPromise
        .then(key => verifyHmac(key, library.library, base64ToUint8(library.hmac)))
        .then(isValid => new Promise((resolve, reject) => isValid ? resolve() : reject('Invalid password or HMAC')))
        .then(() => JSON.parse(library.library))
        .then(library => new Promise((resolve, reject) =>
                library.api_version === apiVersion
                    ? resolve(library)
                    : reject(`Library api version mismatch. Expected ${apiVersion}, got ${library.api_version}`)
            )
        );

    let libraryVersionPromise = libraryPromise.then(library => library.library_version);

    /**
     * @param blob           string
     * @param libraryVersion int
     * @param apiVersion     int
     * @returns object
     */
    function createLibrary(blob, libraryVersion, apiVersion) {
        return {
            blob: blob,
            library_version: libraryVersion,
            api_version: apiVersion,
            modified: Math.round(new Date().getTime() / 1000)
        };
    }

    return {
        getPasswordList: () => Promise
            .all([aesKeyPromise, libraryPromise])
            .then(params => {
                const [key, library] = params;
                const byteArray = base64ToUint8(library.blob);

                return decrypt(key, library.library_version, byteArray);
            })
            .then(decompressFromUint8Array)
            .then(JSON.parse),

        encryptPasswordList: (passwordList, newKey) => {
            libraryVersionPromise = libraryVersionPromise.then(libraryVersion => libraryVersion + 1);

            if (newKey) {
                hmacKeyPromise = getHmacKey(newKey);
                aesKeyPromise = getAesKey(newKey);
                hashPromise = getSha1(newKey);
            }

            const compressedBytes = compressToUint8Array(JSON.stringify(passwordList));

            let blobPromise = Promise.all([aesKeyPromise, libraryVersionPromise])
                .then(params => encryptUint8Array(params[0], compressedBytes, params[1]))
                .then(uint8ToBase64);

            libraryPromise = Promise.all([blobPromise, libraryVersionPromise])
                .then(params => createLibrary(params[0], params[1], apiVersion));

            let libraryJsonPromise = libraryPromise.then(JSON.stringify);

            let hmacPromise = Promise.all([hmacKeyPromise, libraryJsonPromise])
                .then(params => getHmac(params[0], params[1]));

            return Promise.all([libraryJsonPromise, hmacPromise])
                .then(params => {
                    return {
                        library: params[0],
                        hmac: uint8ToBase64(params[1])
                    };
                });
        },

        getHash: () => hashPromise
    };
}

export function generateRandomPassword(length, alphabetHint) {
    const passwordLength = length || 16;
    const alphabet = alphabetHint || 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,?:;[]~!@#$%^&*()-+/';
    const getRandomChar = () => alphabet[Math.floor(Math.random() * alphabet.length)];

    return Array.from({length: passwordLength}, getRandomChar).join('');
}
