import { config } from './config';
import { createCryptoManager, generateRandomPassword } from './crypto';


function decryptLibrary (request) {
  let { masterKey, libraryData } = request;
  let cryptoManager = createCryptoManager(
    masterKey,
    libraryData
  );

  return cryptoManager.getPasswordList();
}

function encryptLibrary (request) {
  let { oldMasterKey, oldLibraryData, newMasterKey, passwords } = request;
  let cryptoManager = createCryptoManager(
    oldMasterKey,
    oldLibraryData
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
