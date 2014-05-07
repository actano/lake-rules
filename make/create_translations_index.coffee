#!/usr/bin/env coffee

coffee = require 'coffee-script'
path = require 'path'

template = ->
    module.exports.availableLanguages = -> XXX
    module.exports.getPhrases = (languageCode) -> require "./#{languageCode}"
    return

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

    entire = template.toString().replace(/XXX/, JSON.stringify languageCodes)
    body = entire.substring entire.indexOf("{") + 1, entire.lastIndexOf("}")
    console.log body
