fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
Promise.promisifyAll fs
mkdirp = Promise.promisify require 'mkdirp'

module.exports =
    coffee: Promise.coroutine (target, src) ->
        CoffeeScript = require 'coffee-script'
        data = yield fs.readFileAsync src, {encoding: 'utf-8'}
        {js, v3SourceMap} = CoffeeScript.compile data, sourceMap: true
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, js
        yield fs.writeFileAsync "#{target}.map", v3SourceMap
        return 0
