#!/usr/bin/env coffee

path = require 'path'

manifestPath = process.argv[2]

if not manifestPath
    console.log "\n\nusage: #{path.basename __filename} Manifest.coffee\n\n"
    process.exit 1

manifest = require path.resolve manifestPath

if not manifest.client.translations
    throw new Error("missing client.translations entry in #{manifestPath}")

for code, file of manifest.client.translations
    manifest.client.translations[code] = file.substr(0, file.lastIndexOf('.'))

indexFunctionTemplate = ->
    module.exports.availableLanguages = -> XXXLC
    module.exports.getPhrases = (languageCode) -> require("../" + XXXLF[languageCode])

ts = indexFunctionTemplate.toString()
ts = ts.replace /XXXLC/, JSON.stringify Object.keys(manifest.client.translations)
ts = ts.replace /XXXLF/, JSON.stringify manifest.client.translations
ts = "(#{ts}).call(this);"

console.log ts
