# shh
A simple ssh client library for node.js.

## Usage
    var shh = require('shh')({
        host: 'example.com',
        user: 'zeekay'
    });

    shh.cmd('ls', function (err, out) {
        console.log(out);
        shh.close();
    });

You can also stream stdout and stderr:

    shh.on('stdout', function (data) {
        console.log(data);
    });
