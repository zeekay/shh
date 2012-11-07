# sshclient
simple ssh client library for node.js

## Usage

    var ssh = require('sshclient')({
        host: 'example.com',
        user: 'zeekay'
    });

    ssh.cmd('ls', function(err, out) {
        console.log(out);
        ssh.close();
    });
