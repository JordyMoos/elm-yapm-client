'use strict';

import Clipboard from 'clipboard';
import config from '../../config.json';
import { decryptLibrary, encryptLibrary } from './js/manager.js';

// require('./index.html');
require("./css/style.css");
require("./css/yapm.css");

let Elm = require('./../elm/Main');
let app = Elm.Main.fullscreen(config);

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

// @todo
let clipboard = new Clipboard('.copyable');
