## Getting started:

- Clone the repository:
  ```sh
  $ git clone https://github.com/JordyMoos/elm-yapm-client.git
  ```
- Install the dependencies:
  ```sh
  $ npm install
  ```
- Set up the yapm php server (https://github.com/marcus/yapm-server)
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

Super cheaty CORS fix in `index.php`
```php
// Add to top of the file
// This allows cross origin requests
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Credentials: true');

// Add just before $app->run();
// This catches all "options" methods
$app->match("{url}", function($url) use ($app) { return "OK"; })->assert('url', '.*')->method("OPTIONS");
```

Run in with php
```sh
$ php -S localhost:8001
```
(Or whatever port is set in yapm-elm-client/config.json)

### Build client:

With npm

```sh
$ npm install
$ npm run dev
```

With yarn
```sh
$ yarn install
$ yarn dev
 ```

Then goto `localhost:3000` in the browser.
