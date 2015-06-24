Promise = require 'bluebird'

mkdirp = Promise.promisify require 'mkdirp'

module.exports = (dir, opts = {}) -> mkdirp dir, opts
