const webpack = require('webpack');

module.exports = [{
  name: 'mirror JS',
  entry: './js-src/mirror.js',
  output: {
    path: __dirname + '/root/static/js',
    filename: 'mirror.js',
  },
}];
