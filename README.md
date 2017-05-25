# Prerequisite:

## Setup the yapm-server:

https://github.com/marcusklaas/yapm-server.git

Run in with php
`php -S localhost:8001` (Or whatever port is set in yapm-elm-client/config.json)


##How to setup dev mode:

Install elm modules
`elm-package install`

Install grunt stuff
`npm install`

Compile elm and assets with grunt
`grunt`

Then goto the index.html's file in your browser.
For example
`file:///home/jordy/workspace/elm-yapm-client/index.html`
