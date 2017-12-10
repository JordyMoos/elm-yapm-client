Yet Another Password Manager Client in Elm
------------------------------------------

This project is based on the the [yet-another-password-manager] from [marcusklaas]

[yet-another-password-manager]: https://github.com/marcusklaas/yapm-client
[marcusklaas]: https://github.com/marcusklaas

## Getting started:

- Clone the repository:
  ```sh
  $ git clone https://github.com/JordyMoos/elm-yapm-client.git
  ```
- Install the dependencies:
  ```sh
  $ npm install
  ```
- Set up the yapm php server (https://github.com/marcusklaas/yapm-server)
- Set the password api endpoint in `config.json`
- Build the client:

  With yarn

  ```sh
  $ yarn prod
  ```

  With npm

  ```sh
  $ npm run prod
  ```

  The resulting file `index.html` will be in the `dist` directory.
- Place the html file on your webserver and chmod it `555`

## How to setup dev mode:

### Setup the yapm-server on your local machine:

Clone
```sh
$ git clone https://github.com/marcusklaas/yapm-server.git
$ cd yapm-server
$ composer install
```

Run in with php
```sh
$ php -S localhost:8001
```

*All requests to /server will be proxied by the webpack devServer to localhost:8001*

### Build client:

With yarn
```sh
$ yarn dev
 ```

Then goto `localhost:3000` in the browser.

### Override config from environment

All keys set in the `config.json` can be overridden with environment variables from their snakecased-upper name.

For example; to override `maxIdleTime` you can set the environment variable `MAX_IDLE_TIME`.
