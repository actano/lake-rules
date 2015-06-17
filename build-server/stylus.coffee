fs = require 'fs'
path = require 'path'

Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
Promise.promisifyAll fs

MODULE_SWITCH = !!process.env['STYLUS_REQUIRE_MODULES']

newline = (s) ->
    s += '\n' unless s.substr(-1) is '\n'
    s

module.exports =
    'stylus': Promise.coroutine (target, src, includePaths...) ->
        stylus = require 'stylus'
        {dirname} = require 'path'

        data = yield fs.readFileAsync src, {encoding: 'utf-8'}
        renderer = stylus(data)
            .set 'filename', src

        for p in includePaths
            p = dirname p if MODULE_SWITCH
            renderer.include p

        Promise.promisifyAll renderer

        css = yield renderer.renderAsync()

        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, newline css
        return 0

