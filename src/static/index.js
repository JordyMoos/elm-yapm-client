'use strict';

import config from '../../config.json';
import { decryptLibrary, encryptLibrary } from './js/manager.js';

// require('./index.html');
require("./css/style.css");
require("./css/yapm.css");

var Elm = require('./../elm/Main');
var app = Elm.Main.fullscreen(config);

app.ports.login.subscribe(function (request) {
  let { masterKey, library } = request;
  decryptLibrary(masterKey, library)
    .then(function (passwords) {
      app.ports.loginSuccess.send({
        library: {
          hmac: library.hmac,
          library: library.library
        },
        masterKey: masterKey,
        passwords: passwords
      });
    })
    .catch(function (error) {
      console.log("error message: " + getErrorMessage(error));

      app.ports.notification.send({
        level: "error",
        message: getErrorMessage(error),
      });
    });
});

app.ports.encryptLibrary.subscribe(function (request) {
  encryptLibrary(request)
    .then(function (data) {
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
    .catch(function (error) {
      app.ports.notification.send({
        level: "error",
        message: getErrorMessage(error),
      });
    });
});

// @todo
// var clipboard = new Clipboard('.copyable');
