fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
Promise.promisifyAll fs
mkdirp = Promise.promisify require 'mkdirp'

module.exports =
    coffee: Promise.coroutine (target, src) ->
        CoffeeScript = require 'coffee-script'
        data = yield fs.readFileAsync src, {encoding: 'utf-8'}
        js = CoffeeScript.compile data
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, js
        return 0
