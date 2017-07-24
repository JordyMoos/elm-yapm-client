'use strict';

import Clipboard from 'clipboard';
import config from '../../config.json';
import { decryptLibrary, encryptLibrary } from './js/manager.js';
const runtime = require('offline-plugin/runtime');

// require('./index.html');
require("./css/style.css");
require("./css/yapm.css");

document.body.innerHTML = '';
let Elm = require('./../elm/Main');
let app = Elm.Main.fullscreen(config);

function getErrorMessage(error) {
  if (typeof(error) === 'string') {
    return error;
  }
  if (typeof(error) === 'object') {
    if (error.message && typeof(error.message) === 'string') {
      return error.message;
    }
  }
  return 'Unknown error';
}

app.ports.login.subscribe(request => {
  let { masterKey, library } = request;
  decryptLibrary(masterKey, library)
    .then(passwords => {
      app.ports.loginSuccess.send({
        library: {
          hmac: library.hmac,
          library: library.library
        },
        masterKey: masterKey,
        passwords: passwords
      });
    })
    .catch(error => {
      app.ports.notification.send({
        level: "error",
        message: getErrorMessage(error),
      });
    });
});

app.ports.encryptLibrary.subscribe(request => {
  encryptLibrary(request)
    .then(data => {
      let [ oldHash, library, newHash ] = data;
      let response = {
        oldHash: oldHash,
        newHash: newHash,
        library: {
          hmac: library.hmac,
          library: library.library
        }
      };
      app.ports.encryptLibrarySuccess.send(response);
    })
    .catch(error => {
      app.ports.notification.send({
        level: "error",
        message: getErrorMessage(error),
      });
    });
});

window.onscroll = () => app.ports.scroll.send({});

let clipboard = new Clipboard('.copyable');


// Service worker
runtime.install({
  onUpdating: () => {
    console.log('SW Event:', 'onUpdating');
  },
  onUpdateReady: () => {
    console.log('SW Event:', 'onUpdateReady');
    // Tells to new SW to take control immediately
    runtime.applyUpdate();
  },
  onUpdated: () => {
    console.log('SW Event:', 'onUpdated');
    // Reload the webpage to load into the new version
    window.location.reload();
  },

  onUpdateFailed: () => {
    console.log('SW Event:', 'onUpdateFailed');
  }
});
