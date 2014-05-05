#!/usr/bin/env coffee

coffee = require 'coffee-script'
path = require 'path'

# TODO this could probably be replaced by much simpler sync code
readStdin = (cb) ->
    input = process.stdin
    buffer = []

    input.resume
    input.setEncoding 'utf8'
    input.on 'data', (chunk) ->
        buffer.push chunk

    input.on 'end', ->
        data = buffer.join()
        cb data


readStdin (data) ->
    manifest = eval coffee.compile data, bare: true

    languageCodes = (key for key of manifest.client.translations)

    console.log "module.exports.availableLanguages = function() { return #{JSON.stringify languageCodes}; };"

    console.log 'module.exports.getPhrases = function(languageCode) {'
    console.log 'switch (languageCode) {'
    for key, script of manifest.client.translations
        file = './' + path.join(path.dirname(script), (path.basename(script, path.extname(script)) + '.js'))
        console.log "case #{JSON.stringify key}: return require(#{JSON.stringify file});"
    console.log '};'
    console.log '};'
