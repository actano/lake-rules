Promise = require 'bluebird'
fs = require 'fs'
path = require 'path'

Promise.promisifyAll fs


server = ->
    dirname = process.argv[2]
    keepAlive = path.join dirname, 'keep-alive'
    command = path.join dirname, 'command'
    result = path.join dirname, 'result'

    interval = null

    processCommand = (args) ->
        switch args[0]
            when 'coffee' then coffee args[1], args[2]
            else 1

    checkExisting = ->
        fs.exists result, (exists) ->
            return if exists
            clearInterval interval
            fs.appendFile command, 'QUIT', ->

    work = Promise.coroutine ->
        data = yield fs.readFileAsync command, {encoding: 'utf-8'}
        args = data.split '\n'
        if args[0] is 'QUIT'
            fs.unlink result, ->
            fs.unlink command, ->
            return false

        try
            exitCode = yield Promise.method(processCommand)(args)
            fs.appendFileAsync result, String(exitCode || 0)
        catch e
            console.error(e)
            fs.appendFileAsync result, "99"

    openExisting = ->
        work().then ->
            process.nextTick openExisting

    openExisting()
    interval = setInterval checkExisting, 500

server()

CoffeeScript = require 'coffee-script'

coffee = Promise.coroutine (target, src) ->
    data = yield fs.readFileAsync src, {encoding: 'utf-8'}
    js = CoffeeScript.compile data
    yield fs.writeFileAsync target, js
    return 0
