# Prerequisite:

## Setup the yapm-server:

Clone
`git clone https://github.com/marcusklaas/yapm-server.git`

`cd yapm-server`

`composer install`

Super cheaty CORS fix in `index.php`
```
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
`php -S localhost:8001` (Or whatever port is set in yapm-elm-client/config.json)


##How to setup dev mode:

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

Then goto `localhost:3000` in the browser
