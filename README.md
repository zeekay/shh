# shh [![Build Status](https://travis-ci.org/zeekay/shh.svg?branch=master)](https://travis-ci.org/zeekay/shh)
A simple ssh client library for node.js. Password authentication is not allowed, so make sure you setup an identity file first.

## Usage
```javascript
var shh = require('shh');

client = new shh.Client({
    host: 'example.com',
    username: 'zeekay'
});

client.connect(function() {
    client.exec('ls', function (err, out) {
        console.log(out);
        client.close();
    });
});
```

You can also stream `stdout` and `stderr` line by line:

```javascript
client.on('stdout', function (line) {
    console.log(line);
});
```
