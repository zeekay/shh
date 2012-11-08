# shh
A simple ssh client library for node.js. Password authentication is not allowed, so make sure you setup an identity file first.

## Usage
    var shh = require('shh')({
        host: 'example.com',
        user: 'zeekay'
        identity: 'key.pem'
    });

    shh.cmd('ls', function (err, out) {
        console.log(out);
        shh.close();
    });

You can also stream stdout and stderr:

    shh.on('stdout', function (data) {
        console.log(data);
    });
