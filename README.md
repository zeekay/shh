# shh
A simple ssh client library for node.js. Password authentication is not allowed, so make sure you setup an identity file first.

## Usage
    var shh = require('shh');

    client = new shh.Client({
        host: 'example.com',
        user: 'zeekay'
    });

    client.cmd('ls', function (err, out) {
        console.log(out);
        client.close();
    });

You can also listen for `stdout` and `stderr` events, `shh` emits each line by line for you:

    client.on('stdout', function (line) {
        console.log(line);
    });
