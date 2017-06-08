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

Install elm modules
`elm-package install`

Install grunt stuff and additional dependencies
`npm install`

Compile elm and assets with grunt
`grunt`

### Now see the password manager

#### Easy approach

Install a cors enabler
https://addons.mozilla.org/nl/firefox/addon/cors-everywhere/

And enable it

Then goto the index.html's file in your browser.
`file:///home/jordy/workspace/elm-yapm-client/index.html`

You need to do `grunt` after every change

#### Alternative approach

Run this in another browser
`elm-reactor`

Then goto `localhost:8000/index.html` in the browser

You probably need to redo `grunt` and `elm-reactor` after every change
