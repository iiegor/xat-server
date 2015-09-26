# xat-server
> Node.js server for xat.com swf files.

This is supposed to be a xat private server that emulates the full functionality of the same built on top of Node.js

## Install
```sh
$ git clone https://github.com/iiegor/xat-server
$ cd xat-server
$ npm install
```

The server depends on [Node.js](http://nodejs.org/), [npm](http://npmjs.org/) and other packages that are downloaded and installed during the install process.

## Run
Execute this command to start the server.
```sh
$ script/run
```
If you want to install a plugin, add it to ``packageDependencies`` in the package.json with the respective version.
Example:
```json
{
  ...
  "packageDependencies": {
    "my-plugin": "0.1.0"
  }
}
```
and run ``$ script/install``.

## Contributors
* **Iegor Azuaga** (dextrackmedia@gmail.com)

### How to contribute
You can contribute to the project by cloning, forking or starring it. If you have any bug, open an issue or if you have an interesting thing you want to implement into the official repository, open a pull request.
