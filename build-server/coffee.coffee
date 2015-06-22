fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
Promise.promisifyAll fs
mkdirp = Promise.promisify require 'mkdirp'

module.exports =
    coffee: Promise.coroutine (target, src) ->
        CoffeeScript = require 'coffee-script'
        data = yield fs.readFileAsync src, {encoding: 'utf-8'}
        options =
            sourceMap: true
            sourceFiles: [src]
            generatedFile: target
        {js, v3SourceMap} = CoffeeScript.compile data, options
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, js
        yield fs.writeFileAsync "#{target}.map", v3SourceMap
        return 0
