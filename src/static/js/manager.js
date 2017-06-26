import { config } from './config';
import { createCryptoManager, generateRandomPassword } from './crypto';


export function decryptLibrary (masterKey, library) {
  let cryptoManager = createCryptoManager(
    masterKey,
    library
  );

  return cryptoManager.getPasswordList();
}

export function encryptLibrary (request) {
  let { oldMasterKey, oldLibrary, newMasterKey, passwords } = request;
  let cryptoManager = createCryptoManager(
    oldMasterKey,
    oldLibrary
  );

  let oldHashPromise = cryptoManager.getHash();
  let libraryPromise = cryptoManager.encryptPasswordList(passwords, newMasterKey);
  let newHashPromise = libraryPromise.then(cryptoManager.getHash);

  return Promise.all([oldHashPromise, libraryPromise, newHashPromise]);
}
