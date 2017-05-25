import { config } from './config';
import { createCryptoManager, generateRandomPassword } from './crypto';


function decryptLibrary (masterKey, library) {
  let cryptoManager = createCryptoManager(
    masterKey,
    library
  );

  return cryptoManager.getPasswordList();
}

function encryptLibrary (request) {
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

function copyPasswordToClipboard (fieldId) {
  console.log('Field id:');
  console.log(fieldId);
}

window.yapm = {
  config: config,
  generateRandomPassword: generateRandomPassword,
  decryptLibrary: decryptLibrary,
  encryptLibrary: encryptLibrary,
  copyPasswordToClipboard: copyPasswordToClipboard,
};
